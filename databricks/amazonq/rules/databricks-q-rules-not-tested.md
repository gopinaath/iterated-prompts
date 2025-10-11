# Amazon Q Rules for Databricks CLI Integration

## Databricks CLI Command Rules

### Workspace Operations
- ALWAYS use `databricks workspace import` instead of `upload` command
- ALWAYS specify `--language PYTHON` (uppercase) for Python notebooks
- ALWAYS use `--overwrite` flag when updating existing notebooks
- Format: `databricks workspace import /path --file filename.py --language PYTHON --overwrite`

### Job Creation and Execution
- ALWAYS use `new_cluster` configuration for job runs, never `existing_cluster_id` with job cluster IDs
- ALWAYS use appropriate cluster sizing: `i3.xlarge` with `num_workers: 1` for small datasets
- ALWAYS include `spark_version: "13.3.x-scala2.12"` in cluster config
- Use JSON format for job creation with proper task structure

### Result Retrieval
- NEVER rely on `notebook_output` field from job run responses (often empty)
- ALWAYS write results to DBFS location: `/dbfs/tmp/filename.txt`
- ALWAYS use `databricks fs cp dbfs:/tmp/filename.txt ./filename.txt` to retrieve results
- Use task run ID (not job run ID) for `databricks jobs get-run-output` command

## Code Generation Rules

### Notebook Structure
- Generate minimal, focused code with only essential imports
- ALWAYS include error handling for data source availability
- ALWAYS include both file output and print statements for results
- Use pandas for data manipulation, requests/BeautifulSoup for web scraping

### Data Analysis Patterns
```python
# ALWAYS check data source availability
if csv_links:
    # Process data
else:
    print("No data source found")

# ALWAYS save results to accessible location
with open("/dbfs/tmp/results.txt", "w") as f:
    f.write(results)

# ALWAYS print results for immediate feedback
print(results)
```

### Column Detection
- Use flexible column detection: `[col for col in df.columns if 'target' in col.lower()]`
- Provide fallback column selection if target columns not found
- ALWAYS validate column existence before processing

## Resource Management Rules

### Cluster Configuration
- Use single-node clusters (`num_workers: 1`) for exploratory analysis
- Set appropriate instance types based on data size
- Include AWS availability zone preferences: `"availability": "SPOT_WITH_FALLBACK"`
- Enable data security mode: `"data_security_mode": "SINGLE_USER"`

### Job Lifecycle
- Create unique job names with timestamps or descriptive suffixes
- Clean up completed jobs when no longer needed
- Monitor job execution status before proceeding to result retrieval

## Error Prevention Rules

### Command Syntax
- Verify Databricks CLI version compatibility before execution
- Use `databricks --help` commands to validate syntax when uncertain
- Test CLI authentication before running complex workflows

### Data Processing
- ALWAYS validate dataset shape and structure before analysis
- Include data quality checks: missing values, data types, row counts
- Handle edge cases: empty datasets, missing columns, network failures

### Output Formatting
- Format numbers with thousands separators: `f"{count:,}"`
- Use consistent ranking format: `f"{i:2d}. **{item}**: {count:,} units"`
- Include metadata: total counts, percentages, data sources, analysis dates

## Workflow Orchestration Rules

### Sequential Execution
- Complete each step fully before proceeding to next
- Validate job completion status before result retrieval
- Provide clear status updates at each workflow stage

### Result Management
- Generate both machine-readable (CSV/JSON) and human-readable (Markdown) outputs
- Include analysis metadata: source URLs, execution timestamps, dataset statistics
- Save results to predictable local file locations for easy access

## Debugging and Troubleshooting Rules

### Logging and Monitoring
- Include verbose print statements in notebooks for debugging
- Log dataset characteristics: shape, columns, sample data
- Capture and display error messages with context

### Fallback Strategies
- Provide alternative approaches when primary methods fail
- Include manual verification steps for critical operations
- Offer Databricks workspace URLs as backup for result viewing

## Integration Best Practices

### User Experience
- Provide immediate feedback on long-running operations
- Explain what each step accomplishes
- Offer next steps and iteration suggestions

### Code Quality
- Generate clean, readable code with appropriate comments
- Use descriptive variable names and function structures
- Follow Python PEP 8 style guidelines where applicable
