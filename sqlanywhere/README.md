# SQL Anywhere to AWS RDS PostgreSQL Migration Prompts

🎯 Look at the updated dates of  prompt files. Models are getting better all the time.  You may be able achieve the same with much simpler prompt!  

 🎯 These are tested with Claude 4 models (Amazon Q Developer CLI and Claude Code).  While these are tested a couple of times and known to work, situations vary, the LLM agentic paths are non-deterministic, your mileage will vary! Observe the coding agent actions and iterate.  

🎯 Consider these as starting prompts.  Review, create your own prompt for your context.  For example, if you think API validation of stored procedures are unnecessary, remove them and run it; if you didn't need GIS extension, change it to use regular PostGreSQL!

🎯 Provide feedback / pull requests

 
## 🚀 Quick Start

### Which Prompt Should I Use?

1. For Migration to Amazon RDS  **`sqlanywhere-to-postgres-on-amazon-rds.md`**.  This can also be used for a remote PostGreSQL database instance hosted on-prem

2. For Migration to Local PostGres Database (with Docker) **`sqlanywhere-to-postgres-on-docker.md`**

### How to Use These Prompts

1. **Copy the prompt** into your AI assistant (**Amazon Q Developer CLI**)
2. **Add your specific details**:
   ```
   Here are my connection details:
   - SQL Anywhere: ServerName=MyServer, DatabaseName=MyDB, UserID=DBA, Password=***
   - RDS PostgreSQL: Host=myinstance.region.rds.amazonaws.com, Database=mydb, User=myuser
   
   Please help me migrate following the prompt guidelines.
   ```
   
## 📋 Migration Checklist

### Before You Start
- [ ] Have RDS PostgreSQL instance provisioned
- [ ] Have Datbase connection credentials - samples given as .txt files.  (format doesn't matter much for PostGres, just ensure all parameters are in the text file)
- [ ] Verify network connectivity between migration server and both databases.  I tested with SQL Anywhere on localhost
- [ ] Install required libraries: `sqlanydb`, `psycopg2-binary`
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
- **AWS Services**: RDS PostgreSQL

## 🤝 Contributing

If you've successfully used these prompts and discovered improvements, share those; feel free to submit a PR.

