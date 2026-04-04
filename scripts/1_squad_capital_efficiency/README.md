# Transfermarkt Data Analysis SQL Project

## Project Overview

**Analysis Title**: Squad Capital Efficiency (SCE) - Season 2025  
**Database**: `PostgreSQL 16+`  
**Schema**: `gold.`  
**Target Audience**: Club Sporting Directors & Financial Analysts  

## Objectives

1.  **Business Analysis**: Evaluate the **Capital Efficiency (ROI)** of football clubs for the 2025 season.
2.  **Financial KPI**: Identify "Moneyball" overperformers by calculating the **Cost per Point** (Market Value in M€ / Total League Points).

## Analysis Structure

### 1. Methodology
We join player-level valuations with match-day performance metrics. To ensure accuracy, we don't just take the "latest" valuation; we use a window function to find the valuation record closest to the player's first appearance in the 2025 season for that specific club to avoid market volatility bias.

### 2. SQL Implementation

The following production-grade query identifies which clubs are most efficient at converting market value into league points.

### 1. 

- ** **: 

```sql

```

### 2. 

The following SQL queries were developed to answer specific business questions:

1. ** **:
```sql

```

2. ** **:
```sql

```

3. ** **:
```sql

```

4. ** **:
```sql

```

5. ** **:
```sql

```

## Findings

- 


## Conclusion



## How to Use

1. **Clone the Repository**: Clone this project repository from GitHub.
2. **Set Up the Database**: Run the SQL scripts provided in the [0_database_initialization](./scripts/0_database_initialization) file to create and populate the database.
3. **Run the Queries**: Use the SQL queries provided in the `1_squad_capital_efficiency_analysis.sql` file to perform your analysis.
4. **Explore and Modify**: Feel free to modify the queries to explore different aspects of the dataset or answer additional business questions.
