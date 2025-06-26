## The Prompt

```
I need to migrate my SQL Anywhere database to AWS RDS PostgreSQL. Please help me create a complete migration solution with the following approach:

1. **SETUP PHASE**
   - Connect to existing AWS RDS PostgreSQL instance (connection details provided separately)
   - Install required extensions: `CREATE EXTENSION IF NOT EXISTS postgis;` (for spatial data)
   - Create a dedicated schema (not public) for the migrated database: `CREATE SCHEMA IF NOT EXISTS myapp;`
   - Configure all connections to use this schema via search_path: `SET search_path TO myapp, public;`
   - Verify RDS instance has sufficient storage and compute for migration workload

2. **DISCOVERY PHASE**
   Create a Python script to extract from SQL Anywhere:
   - All tables with columns, types, and sizes
   - All foreign key relationships (watch for circular dependencies)
   - All stored procedures with their full definitions
   - Identify which tables have: LONG BINARY, LONG VARCHAR, BIT, ST_GEOMETRY types
   - Count rows in each table
   - Group tables into logical domains (Sales, HR, Finance, etc.)
   - Estimate total data size for RDS capacity planning

3. **MIGRATION STRATEGY**
   Create a phased migration plan:
   - Phase 1: Independent tables (no foreign keys)
   - Phase 2-N: Tables in dependency order
   - Special Phase: Tables with circular foreign keys (create without FKs, migrate data, add FKs)
   - Final Phase: Stored procedures and views
   - Consider RDS connection limits and batch sizes for large tables

4. **FOR EACH TABLE**
   Create these scripts:
   - Extract script: Get schema and sample data from SQL Anywhere
   - PostgreSQL DDL: Convert using these mappings:
     * LONG BINARY → BYTEA
     * LONG VARCHAR → TEXT
     * BIT → BOOLEAN
     * ST_GEOMETRY → geometry (requires PostGIS extension)
     * All identifiers → lowercase
   - Migrate script: Copy data with proper type conversions and batch processing
   - Validate script: Compare row counts and sample data
   - Use connection pooling for RDS efficiency

5. **STORED PROCEDURE CONVERSION**
   For each SQL Anywhere procedure:
   - Convert to PostgreSQL function that RETURNS TABLE
   - Change TOP n to LIMIT n
   - Handle output parameters by including them in RETURNS TABLE
   - IMPORTANT: Test if procedures return results for INSERT/UPDATE/DELETE operations
   - If not, document this behavior and handle in application layer
   - Consider RDS parameter groups for function-specific settings

6. **CRITICAL CHECKS**
   - Circular foreign keys: Use 3-step migration (create, load, constrain)
   - Case sensitivity: Always use lowercase in PostgreSQL
   - NULL handling: Add explicit type casts for function parameters
   - Spatial data: Normalize WKT format (use 0.5 not .5)
   - Binary data: Test with actual file content, not just migration
   - Transaction behavior: PostgreSQL auto-begins transactions
   - RDS-specific: Monitor CloudWatch metrics during migration
   - Connection management: Handle RDS connection timeouts and limits

7. **DATABASE ABSTRACTION LAYER**
   Create a unified API that works with both databases:
   
   ```python
   # Base abstract class defining the interface
   class DatabaseAdapter(ABC):
       @abstractmethod
       def connect(self) -> None: pass
       
       @abstractmethod
       def disconnect(self) -> None: pass
       
       # For each stored procedure, create a method:
       @abstractmethod
       def show_contacts(self, contact_id: Optional[int] = None) -> List[Dict[str, Any]]: pass
       
       @abstractmethod
       def manage_contacts(self, action: str, **kwargs) -> Optional[Dict[str, Any]]: pass
       
       # ... method for each stored procedure
   ```
   
   Then implement for each database:
   - `SQLAnywhereAdapter`: Calls stored procedures, handles missing results
   - `RDSPostgreSQLAdapter`: Calls functions, normalizes column names, handles RDS specifics
   
   Key adapter responsibilities:
   - Connection management with RDS SSL requirements
   - Connection pooling for RDS efficiency
   - Column name normalization (SQL Anywhere: 'ID', PostgreSQL: 'id')
   - Handle procedures that don't return results (fetch after INSERT/UPDATE)
   - Generate IDs before INSERT if procedures expect them
   - Consistent error handling across databases
   - RDS-specific timeout and retry logic

8. **RDS-SPECIFIC CONSIDERATIONS**
   - Use SSL connections: `sslmode=require` in connection string
   - Monitor RDS CloudWatch metrics: CPU, connections, storage
   - Consider Multi-AZ for production migrations
   - Use RDS parameter groups for PostgreSQL tuning
   - Plan for RDS maintenance windows
   - Backup strategy: Point-in-time recovery vs manual snapshots
   - Consider read replicas for minimal downtime migrations
   - Network security: VPC, security groups, subnet groups
   - IAM database authentication if required

9. **VALIDATION REQUIREMENTS**
   For each phase, verify:
   - Row counts match exactly
   - Foreign key relationships are intact
   - Sample data comparison (first/last 10 rows)
   - Stored procedures return identical results
   - No orphaned foreign key references
   - RDS performance metrics within acceptable ranges
   - SSL connection verification
   - Backup and restore testing

10. **PERFORMANCE OPTIMIZATION**
    - Use COPY for bulk data loading
    - Adjust RDS instance class if needed during migration
    - Consider temporary parameter adjustments (maintenance_work_mem, etc.)
    - Monitor and optimize slow queries
    - Plan index creation strategy
    - Use RDS Performance Insights for monitoring

Please structure the migration as separate phases, validate each phase before proceeding, maintain 100% data integrity throughout, and optimize for RDS-specific performance characteristics. Document any behavioral differences discovered.
```

## RDS-Specific Quick Reference

### Connection Configuration
```python
# RDS PostgreSQL connection
import psycopg2

connection_params = {
    'host': 'your-rds-endpoint.region.rds.amazonaws.com',
    'port': 5432,
    'database': 'your_database',
    'user': 'your_username',
    'password': 'your_password',
    'sslmode': 'require',  # Required for RDS
    'connect_timeout': 30,
    'options': '-c search_path=myapp,public'
}

conn = psycopg2.connect(**connection_params)
```

### RDS Performance Considerations
```sql
-- Temporary settings for migration (via RDS parameter group)
shared_preload_libraries = 'pg_stat_statements'
max_connections = 200
work_mem = '256MB'
maintenance_work_mem = '2GB'
checkpoint_completion_target = 0.9
wal_buffers = '16MB'
```

### Data Type Mappings
```sql
SQL Anywhere          → RDS PostgreSQL
-----------------      ----------------
LONG BINARY          → BYTEA
LONG VARCHAR         → TEXT
BIT                  → BOOLEAN
ST_GEOMETRY          → geometry (PostGIS)
INTEGER              → INTEGER
VARCHAR(n)           → VARCHAR(n)
NUMERIC/DECIMAL      → NUMERIC/DECIMAL
DATE                 → DATE
TIMESTAMP            → TIMESTAMP
```

### RDS-Specific Gotchas
1. **SSL Required**: All connections must use SSL
2. **Connection Limits**: Monitor active connections via CloudWatch
3. **Storage**: Ensure sufficient space for migration + growth
4. **Backups**: Automated backups during migration window
5. **Parameter Groups**: Changes require reboot for some parameters
6. **Monitoring**: Use CloudWatch + Performance Insights
7. **Security Groups**: Must allow inbound on port 5432
8. **Subnets**: RDS requires subnet group with multiple AZs

### API Patterns for Stored Procedures

**Read-Only Procedures** (ShowContacts, ShowCustomers, etc.):
```python
def show_contacts(self, contact_id: Optional[int] = None) -> List[Dict[str, Any]]:
    # SQL Anywhere: CALL ShowContacts(?)
    # RDS PostgreSQL: SELECT * FROM showcontacts(?)
    # Return: List of contact dictionaries
```

**CRUD Procedures** (ManageContacts):
```python
def manage_contacts(self, action: str, **kwargs) -> Optional[Dict[str, Any]]:
    # Actions: 'L'ist, 'I'nsert, 'U'pdate, 'D'elete
    # SQL Anywhere: May not return results for I/U/D
    # RDS PostgreSQL: Returns results for all actions
    # Handle ID generation for inserts
```

**Complex Procedures** (debugger_tutorial):
```python
def debugger_tutorial(self) -> Tuple[str, int]:
    # Preserve exact behavior including bugs for compatibility
    # Document any behavioral quirks
```

### Migration Checklist
- [ ] RDS instance provisioned with sufficient resources
- [ ] PostGIS extension installed on RDS
- [ ] SSL certificates configured
- [ ] Schema creation with proper search_path
- [ ] Security groups and network access configured
- [ ] CloudWatch monitoring enabled
- [ ] Dependency analysis and phase planning
- [ ] Table-by-table migration with validation
- [ ] Stored procedure conversion and testing
- [ ] Database adapter API implementation
- [ ] API compatibility testing between adapters
- [ ] Foreign key verification
- [ ] Performance monitoring via RDS metrics
- [ ] Backup and disaster recovery testing
- [ ] Documentation of differences

### RDS Migration Best Practices
1. **Pre-Migration**: Take RDS snapshot before starting
2. **During Migration**: Monitor CloudWatch metrics continuously
3. **Batch Processing**: Use appropriate batch sizes for large tables
4. **Connection Pooling**: Implement connection pooling for efficiency
5. **SSL Security**: Always use encrypted connections
6. **Parameter Tuning**: Optimize RDS parameters for migration workload
7. **Monitoring**: Set up CloudWatch alarms for key metrics
8. **Testing**: Validate on RDS read replica first if possible

