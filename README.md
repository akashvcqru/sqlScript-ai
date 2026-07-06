# VCQRU SQL Scripts

This repository contains all SQL scripts and database objects for the VCQRU project.

---

## 📁 Folder Structure

| Folder | Purpose |
|--------|---------|
| `Migrations/` | Schema change scripts — run in order on each environment |
| `StoredProcedures/` | Full SP definitions — source of truth for all procedures |
| `Tables/` | Table CREATE scripts and reference data |
| `Jobs/` | SQL Server Agent job scripts |
| `Functions/` | Scalar and table-valued function scripts |
| `Views/` | Database view scripts |
| `Triggers/` | Database trigger scripts |
| `Indexes/` | Index creation and optimization scripts |
| `Rollback/` | Undo scripts corresponding to each migration |
| `SeedData/` | Initial/reference data inserts |

---

## 🚀 How to Deploy

### Deploy a Single SP to UAT
Run the SP file directly in SSMS connected to UAT:
```sql
-- Open the file from StoredProcedures/ and execute
```

### Deploy All SPs (via PowerShell)
A deployment script reads from `appsettings.Development.json` automatically.

---

## 📋 Migration Workflow

### Every time you make a DB change:

1. **Create a Migration file**
   ```
   Migrations/YYYYMMDD_ShortDescription.sql
   ```
   Example: `20260703_AddColumnToConsumer.sql`

2. **Create a matching Rollback file**
   ```
   Rollback/20260703_ShortDescription_Rollback.sql
   ```

3. **Run on UAT first**, verify, then run on **PROD**

4. **Commit to Git** so the team knows what changed

---

## 🔍 How to Find What Changed on UAT

Run on UAT to find all SPs modified after a date:
```sql
SELECT name, modify_date
FROM sys.objects
WHERE type = 'P'
  AND modify_date >= '2026-06-01'
ORDER BY modify_date DESC;
```

---

## 📌 Naming Conventions

| Object | Convention | Example |
|--------|-----------|---------|
| Stored Procedures | `USP_` or `SP_BL_` prefix + `_AI` suffix | `USP_GetUserReport_AI.sql` |
| Migrations | `YYYYMMDD_Description.sql` | `20260703_AddColumns.sql` |
| Rollbacks | `YYYYMMDD_Description_Rollback.sql` | `20260703_AddColumns_Rollback.sql` |
| Tables | PascalCase table name | `ConsumerPointsCashDetails.sql` |
| Indexes | `IX_TableName_Column.sql` | `IX_ProEnq_CompId.sql` |

---

## ⚠️ Important Rules

- **Never hardcode passwords** in any script file
- Always use `CREATE OR ALTER PROCEDURE` (not `CREATE` or `ALTER` alone)
- Always use `IF NOT EXISTS` guards in migration scripts so they are **safe to re-run**
- Test on **UAT first**, then deploy to **PROD**
- All migration scripts must be committed to Git **before** running on PROD
