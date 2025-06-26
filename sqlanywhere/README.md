# SQL Anywhere to AWS RDS PostgreSQL Migration Toolkit

## 🎯 Problem Statement

Migrating from SQL Anywhere to AWS RDS PostgreSQL is a complex challenge that involves:

- **Incompatible SQL dialects** requiring syntax conversion
- **Different system catalogs** making schema discovery difficult  
- **Library limitations** (e.g., sqlanydb doesn't support Python context managers)
- **Data type mismatches** requiring careful mapping
- **Stored procedure conversion** from Watcom-SQL to PL/pgSQL
- **RDS-specific requirements** like mandatory SSL and connection limits
- **Circular foreign keys** requiring special handling

Without proper guidance, teams waste 60-70% of their time debugging issues that could have been avoided.

## 🚀 Quick Start

### Which Prompt Should I Use?

1. **`sqlanywhere-to-postgres-on-amazon-rds-v2.md`** (RECOMMENDED)
   - Includes mandatory Phase 0 validation
   - Battle-tested with real migrations
   - Mildly complex code snippets included to further optimize migrations (L200 level)

2. **`sqlanywhere-to-postgres-on-amazon-rds-v2`**
   - Based on lessons from actual migration
   - Best for avoiding common pitfalls
   - Includes specific code examples

3. **`sqlanywhere-to-postgres-on-docker.md`**
   - Original comprehensive guide
   - Good for architecture planning
   - Easy to read and understand (L100 level)

### How to Use These Prompts

1. **Copy the unified prompt** into your AI assistant (**Amazon Q Developer CLI**)
2. **Add your specific details**:
   ```
   Here are my connection details:
   - SQL Anywhere: ServerName=MyServer, DatabaseName=MyDB, UserID=DBA, Password=***
   - RDS PostgreSQL: Host=myinstance.region.rds.amazonaws.com, Database=mydb, User=myuser
   
   Please help me migrate following the prompt guidelines.
   ```
3. **Follow Phase 0 FIRST** - This is critical for success
4. **Work through each phase** systematically

## 📋 Migration Checklist

### Before You Start
- [ ] Have RDS PostgreSQL instance provisioned
- [ ] Have Datbase connection credentials - samples given as .txt files.  (format doesn't matter, just ensure all parameters are in the text file)
- [ ] Verify network connectivity between migration server and both databases
- [ ] Install required libraries: `sqlanydb`, `psycopg2-binary`
- [ ] Have AWS CLI configured for RDS management

### Phase 0: Environment Validation (CRITICAL)
- [ ] Test SQL Anywhere connection without context managers
- [ ] Verify RDS SSL connection works
- [ ] Run system catalog test queries
- [ ] Document actual user IDs (not USER_ID() function)
- [ ] Identify tables with special data types

### Migration Phases
- [ ] Phase 1: Setup & Infrastructure
- [ ] Phase 2: Discovery & Analysis  
- [ ] Phase 3: Proof of Concept (single table/procedure)
- [ ] Phase 4: Scaled Migration
- [ ] Phase 5: Stored Procedure Conversion
- [ ] Phase 6: API Integration (if needed)
- [ ] Phase 7: Validation & Monitoring

## 🛠️ Common Use Cases

### Case 1: Simple Database Migration
```bash
# Use unified prompt with focus on Phases 0-4 and 7
# Skip Phase 6 (API Integration) if not needed
```

### Case 2: Migration with API Modernization  
```bash
# Use full unified prompt
# Pay special attention to Phase 6 for REST API creation
# Consider the database abstraction layer pattern
```

### Case 3: Stored Procedure Heavy System
```bash
# Use unified prompt with emphasis on Phase 5
# Document behavior differences carefully
# Test extensively with real data
```

## 🚨 Critical Warnings

1. **sqlanydb Limitation**
   ```python
   # WRONG - This will fail!
   with sqlanydb.connect(...) as conn:
       cursor = conn.cursor()
   
   # CORRECT
   conn = sqlanydb.connect(...)
   cursor = conn.cursor()
   try:
       # your code
   finally:
       cursor.close()
       conn.close()
   ```

2. **RDS SSL Requirement**
   ```python
   # This is MANDATORY for RDS
   conn = psycopg2.connect(
       host='your-instance.region.rds.amazonaws.com',
       sslmode='require'  # or 'require' 
   )
   ```

3. **Exact Type Matching**
   ```sql
   -- If SQL Anywhere column is SMALLINT, use SMALLINT in PostgreSQL
   -- Don't "upgrade" to INTEGER - functions will fail!
   ```

## 🔧 Troubleshooting

### Connection Issues
1. Check security groups allow port 5432
2. Verify RDS subnet group configuration  
3. Test with `psql` command-line first
4. Ensure SSL certificates are available

### Type Conversion Problems
1. Use the exact mappings in the prompt
2. Test with sample data first
3. Pay attention to SMALLINT vs INTEGER
4. Handle BIT → BOOLEAN with `bool(int(value))`

### Performance Issues
1. Monitor RDS CloudWatch metrics
2. Adjust batch sizes based on connection limits
3. Use connection pooling
4. Consider temporary parameter group changes

## 📚 Additional Resources

### Tools Used
- **Python Libraries**: `sqlanydb`, `psycopg2-binary`, `boto3`
- **Node.js Libraries**: `pg`, `express` (for API)
- **AWS Services**: RDS PostgreSQL, CloudWatch, Parameter Groups

### Related Files in This Project
- `migrate_procedures.py` - Example procedure migration script
- `server.js` - Example REST API implementation
- `validation_report.txt` - Sample validation output
- `CURL_COMMANDS_READY_TO_USE.md` - API testing examples

## 🤝 Contributing

If you've successfully used these prompts and discovered improvements:
1. Document your lessons learned
2. Update the prompt with specific examples
3. Share metrics from your migration


**Remember**: The key to success is following Phase 0 completely before writing any migration code. This alone will save you days of debugging!
