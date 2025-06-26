#  SQL Anywhere to PostgreSQL on Docker Migration Prompt


```
I need to migrate my SQL Anywhere database to PostgreSQL. Please help me create a complete migration solution with the following approach:

1. **SETUP PHASE**
   - Use PostgreSQL on Amazon RDS.  Connection details specified in a separate file in this directory.   
   - Create a dedicated schema (not public) for the migrated database.  Pick a suitable schema name based on SQL Anywhere database name.
   - Configure all connections to use this schema
   - Test connectivity to databases.  PostGreSQL should be already running.  If not, proceed with setting up PostgreSQL docker container as specified. Same with SQLAnywhere.  If these don't work, stop the process and ask the user for inputs.
   - Use venv.  Install required dependencies for database connectivity, API, etc.
   - Assume you have enough storage space

2. **DISCOVERY PHASE**
   Create a Python script to extract from SQL Anywhere:
   - All tables with columns, types, and sizes
   - All foreign key relationships (watch for circular dependencies)
   - All stored procedures with their full definitions
   - Identify which tables have: LONG BINARY, LONG VARCHAR, BIT, ST_GEOMETRY types
   - Count rows in each table
   - Group tables into logical domains (Sales, HR, Finance, etc.)

3. **MIGRATION STRATEGY**
   Create a phased migration plan:
   - Phase 1: Independent tables (no foreign keys)
   - Phase 2-N: Tables in dependency order
   - Special Phase: Tables with circular foreign keys (create without FKs, migrate data, add FKs)
   - Final Phase: Stored procedures and views

4. **FOR EACH TABLE**
   Create these scripts:
   - Extract script: Get schema and sample data from SQL Anywhere
   - PostgreSQL DDL: Convert using these mappings:
     * LONG BINARY → BYTEA
     * LONG VARCHAR → TEXT
     * BIT → BOOLEAN
     * ST_GEOMETRY → geometry (requires PostGIS)
     * All identifiers → lowercase
   - Migrate script: Copy data with proper type conversions
   - Validate script: Compare row counts and sample data

5. **STORED PROCEDURE CONVERSION**
   For each SQL Anywhere procedure:
   - Convert to PostgreSQL function that RETURNS TABLE
   - Change TOP n to LIMIT n
   - Handle output parameters by including them in RETURNS TABLE
   - IMPORTANT: Test if procedures return results for INSERT/UPDATE/DELETE operations
   - If not, document this behavior and handle in application layer

6. **CRITICAL CHECKS**
   - Circular foreign keys: Use 3-step migration (create, load, constrain)
   - Case sensitivity: Always use lowercase in PostgreSQL
   - NULL handling: Add explicit type casts for function parameters
   - Spatial data: Normalize WKT format (use 0.5 not .5)
   - Binary data: Test with actual file content, not just migration
   - Transaction behavior: PostgreSQL auto-begins transactions

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
       def show_entities(self, entity_id: Optional[int] = None) -> List[Dict[str, Any]]: pass
       
       @abstractmethod
       def manage_entities(self, action: str, **kwargs) -> Optional[Dict[str, Any]]: pass
       
       # ... method for each stored procedure
   ```
   
   Then implement for each database:
   - `SQLAnywhereAdapter`: Calls stored procedures, handles missing results
   - `PostgreSQLAdapter`: Calls functions, normalizes column names
   
   Key adapter responsibilities:
   - Connection management with proper schema paths
   - Column name normalization (SQL Anywhere: 'ID', PostgreSQL: 'id')
   - Handle procedures that don't return results (fetch after INSERT/UPDATE)
   - Generate IDs before INSERT if procedures expect them
   - Consistent error handling across databases
   - Transaction management differences

8. **VALIDATION REQUIREMENTS**
   For each phase, verify:
   - Row counts match exactly
   - Foreign key relationships are intact
   - Sample data comparison (first/last 10 rows)
   - Stored procedures return identical results
   - No orphaned foreign key references

Please structure the migration as separate phases, validate each phase before proceeding, and maintain 100% data integrity throughout. Document any behavioral differences discovered.

If there are errors encountered, iterate to resolve.

```

## Quick Reference Card

### Data Type Mappings
```sql
SQL Anywhere          → PostgreSQL
-----------------      -----------
LONG BINARY          → BYTEA
LONG VARCHAR         → TEXT
BIT                  → BOOLEAN
ST_GEOMETRY          → geometry
INTEGER              → INTEGER
VARCHAR(n)           → VARCHAR(n)
NUMERIC/DECIMAL      → NUMERIC/DECIMAL
DATE                 → DATE
TIMESTAMP            → TIMESTAMP
```

### Common Gotchas
1. **Case**: `MyTable` becomes `mytable` in PostgreSQL
2. **Procedures**: May not return results for INSERT/UPDATE/DELETE
3. **Syntax**: `TOP 10` becomes `LIMIT 10`
4. **Functions**: `ShowEntities(NULL)` needs `ShowEntities(NULL::INTEGER)`
5. **IDs**: SQL Anywhere uses manual `MAX(id)+1`, not sequences

### API Patterns for Stored Procedures

**Read-Only Procedures** (ShowEntities,  etc.):
```python
def show_entities(self, enitity_id: Optional[int] = None) -> List[Dict[str, Any]]:
    # SQL Anywhere: CALL ShowEntities(?)
    # PostgreSQL: SELECT * FROM showentities(?)
    # Return: List of entity dictionaries
```

**CRUD Procedures** (ManageEntities):
```python
def manage_entities(self, action: str, **kwargs) -> Optional[Dict[str, Any]]:
    # Actions: 'L'ist, 'I'nsert, 'U'pdate, 'D'elete
    # SQL Anywhere: May not return results for I/U/D
    # PostgreSQL: Returns results for all actions
    # Handle ID generation for inserts
```

**Complex Procedures** :
```python
    # Document any behavioral quirks
```

### Migration Checklist
- [ ] Docker PostgreSQL with persistent volume
- [ ] Schema creation with proper search_path
- [ ] Dependency analysis and phase planning
- [ ] Table-by-table migration with validation
- [ ] Stored procedure conversion and testing
- [ ] Database adapter API implementation
- [ ] API compatibility testing between adapters
- [ ] Foreign key verification
- [ ] Documentation of differences



