library(usethis)
library(tidyverse)
library(shiny)
library(DBI)
library(duckdb)
library(gt)
library(thematic)
library(bslib)
library(ellmer)
library(shinychat)
library(coro)
library(httr2)
library(rsconnect)
library(rmarkdown)
library(knitr)
library(reticulate)
library(here)

# connect to db ensuring read only mode to avoid db injection of data
con <- dbConnect(duckdb(), dbdir = here("bank.duckdb"), read_only = TRUE)

# list of tables
table_list <- dbListTables(con)
table_list
DBI::dbExecute(con, "INSTALL icu;")
DBI::dbExecute(con, "LOAD icu;")



# Dynamically create the system prompt, based on the real data. For an actually
# large database, you wouldn't want to retrieve all the data like this, but
# instead either hand-write the schema or write your own routine that is more
# efficient than system_prompt().
## system_prompt_str <- system_prompt(dbGetQuery(con, "SELECT * FROM bank"), "bank")
system_prompt_str <- "
Table: bank
Columns:
- id_account (INTEGER)
- id_customer (INTEGER)
- id_account_type (INTEGER)
- desc_account_type (VARCHAR)
- first_name (VARCHAR)
- last_name (VARCHAR)
- birthday (DATE)
- date_transaction (DATE)
- id_transaction_type (INTEGER)
- amount_transaction (FLOAT)
- desc_transaction_type (VARCHAR)
- sign_transaction (VARCHAR)
"

### PAGE 2 ###

# New markdown file
greeting <- paste(readLines(here("greetings.md")), collapse = "\n")
icon_explain <- tags$img(src = "stars.svg")

# Age of customer (from customer table)
query1 <- "SELECT DISTINCT(id_customer), date_diff('year', birthday, CURRENT_DATE) AS age
  FROM bank
  ORDER BY id_customer;"

# Number of outgoing transactions on all accounts.
query2 <- "SELECT id_account, sign_transaction, COUNT(*) AS n_outgoing
  FROM bank
  GROUP BY id_account, sign_transaction
  HAVING sign_transaction = '-'
  ORDER BY sign_transaction, id_account;
"
# Total amount transacted out on all accounts
query3 <- "SELECT sign_transaction, SUM(amount_transaction) AS total
  FROM bank
  GROUP BY sign_transaction
  HAVING sign_transaction = '-';"
# Total amount transacted incoming on all accounts
query4 <- "SELECT sign_transaction, SUM(amount_transaction) AS total
  FROM bank
  GROUP BY sign_transaction
  HAVING sign_transaction = '+';"
# Total number of accounts held.
query5 <- "SELECT id_customer, COUNT(id_account) AS n_account
  FROM bank
  GROUP BY id_customer;"
# Number of accounts held by type (one indicator for each type of account)
query6 <- "SELECT desc_account_type, COUNT(desc_account_type) AS n_desc_account_type
  FROM bank
  GROUP BY desc_account_type;"
# Number of outgoing transactions by account type (one indicator per account type).
query7 <- "SELECT desc_account_type, COUNT(*) AS n_outgoing
  FROM bank
  WHERE sign_transaction == '-'
  GROUP BY desc_account_type;"
# Number of incoming transactions by account type (one indicator per account type).
query8 <- "SELECT desc_account_type, COUNT(*) AS n_outgoing
  FROM bank
  WHERE sign_transaction == '+'
  GROUP BY desc_account_type;"
# Outgoing transacted amount by account type (one indicator per account type).
query9 <- "SELECT desc_account_type, sign_transaction, SUM(amount_transaction) AS total_outgoing
  FROM bank
  GROUP BY desc_account_type, sign_transaction
  HAVING sign_transaction = '-'
  ORDER BY sign_transaction;"
# Amount transacted inbound by account type (one indicator per account type).
query10 <- "SELECT desc_account_type, sign_transaction, SUM(amount_transaction) AS total_outgoing
  FROM bank
  GROUP BY desc_account_type, sign_transaction
  HAVING sign_transaction = '+'
  ORDER BY sign_transaction;"
# feature table
query11 <- "SELECT 
    customers.id_customer,
    DATE_DIFF('year', ANY_VALUE(customers.birthday), CURRENT_DATE) AS age,
    COUNT(CASE WHEN transaction_type.sign = '-' THEN 1 ELSE NULL END) AS n_out_transactions,
    COUNT(CASE WHEN transaction_type.sign = '+' THEN 1 ELSE NULL END) AS n_in_transactions,
    SUM(CASE WHEN transaction_type.sign = '-' THEN transactions.amount ELSE 0 END) AS tot_out,
    SUM(CASE WHEN transaction_type.sign = '+' THEN transactions.amount ELSE 0 END) AS tot_in,
    COUNT(DISTINCT account.id_account) AS n_account,

    COUNT(CASE WHEN account_type.desc_account_type = 'Conto Privati' THEN 1 ELSE NULL END) AS n_private_account,
    COUNT(CASE WHEN account_type.desc_account_type = 'Conto Base' THEN 1 ELSE NULL END) AS n_base_account,
    COUNT(CASE WHEN account_type.desc_account_type = 'Conto Business' THEN 1 ELSE NULL END) AS n_business_account,
    COUNT(CASE WHEN account_type.desc_account_type = 'Conto Famiglie' THEN 1 ELSE NULL END) AS n_family_account,

    SUM(CASE WHEN account_type.desc_account_type = 'Conto Privati' AND transaction_type.sign = '-' THEN transactions.amount ELSE 0 END) AS tot_out_private_account,
    SUM(CASE WHEN account_type.desc_account_type = 'Conto Base' AND transaction_type.sign = '-' THEN transactions.amount ELSE 0 END) AS tot_out_base_account,
    SUM(CASE WHEN account_type.desc_account_type = 'Conto Business' AND transaction_type.sign = '-' THEN transactions.amount ELSE 0 END) AS tot_out_business_account,
    SUM(CASE WHEN account_type.desc_account_type = 'Conto Famiglie' AND transaction_type.sign = '-' THEN transactions.amount ELSE 0 END) AS tot_out_family_account,

    SUM(CASE WHEN account_type.desc_account_type = 'Conto Privati' AND transaction_type.sign = '+' THEN transactions.amount ELSE 0 END) AS tot_in_private_account,
    SUM(CASE WHEN account_type.desc_account_type = 'Conto Base' AND transaction_type.sign = '+' THEN transactions.amount ELSE 0 END) AS tot_in_base_account,
    SUM(CASE WHEN account_type.desc_account_type = 'Conto Business' AND transaction_type.sign = '+' THEN transactions.amount ELSE 0 END) AS tot_in_business_account,
    SUM(CASE WHEN account_type.desc_account_type = 'Conto Famiglie' AND transaction_type.sign = '+' THEN transactions.amount ELSE 0 END) AS tot_in_family_account
  FROM customers
  LEFT JOIN account ON customers.id_customer = account.id_customer
  LEFT JOIN account_type ON account.id_account_type = account_type.id_account_type
  LEFT JOIN transactions ON account.id_account = transactions.id_account
  LEFT JOIN transaction_type ON transactions.id_transaction_type = transaction_type.id_transaction_type
  GROUP BY customers.id_customer;
"


ids <- c("query1", "query2", "query3", "query4", "query5", "query6", "query7", "query8", "query9", "query10", "query11")
queries <- c(query1, query2, query3, query4, query5, query6, query7, query8, query9, query10, query11)
texts<- c("Age of customer", "Number of outgoing transactions on all accounts", "Total amount transacted out on all accounts", "Total amount transacted incoming on all accounts", "Total number of accounts held", "Number of accounts held by type", "Number of outgoing transactions by account type", "Number of incoming transactions by account type", "Outgoing transacted amount by account type", "Amount transacted inbound by account type", "Feature table for ML model")



queries_lst <- setNames(queries, texts)

onStop(\() dbDisconnect(con))

