source("global.R")


ui <- navbarPage(
  
  # set flatly theme
  theme = bslib::bs_theme(version = 5, bootswatch = "flatly"),
  # theme = bs_theme(brand = TRUE),
  
  
  title = "Database Explorer",
  
  ### PAGE 1 ###
  tabPanel("Table Finder",
           page_sidebar(
             sidebar = sidebar(
               selectizeInput(
                 inputId = "table",
                 label = "Select table",
                 choices = table_list,
                 selected = "bank"
               ),
               actionButton(
                 inputId = "submit",
                 label = "Show table",
                 icon = icon("play")
               ),
             ),
             gt_output("table")
           )
  ),
  
  ### PAGE 2 ###
  tabPanel("Pre-made Query",
           page_sidebar(
             sidebar = sidebar(
               
               selectizeInput(
                 inputId = "premade_query",
                 label = "Select premade query",
                 choices = queries_lst,
                 # selected = "query1"
               ),
               actionButton(
                 inputId = "submit_premade_query",
                 label = "Submit premade query",
                 icon = icon("play")
               ),
               textOutput("premade_query"),
             ),
             gt_output("table_premade_query")
           )
  ),
  
  ### PAGE 3 ###
  tabPanel("Query Maker",
           page_sidebar(
             sidebar = sidebar(
               textAreaInput(
                 inputId = "query",
                 label = "Qrite a SQL query",
                 value = "SELECT * FROM bank"
               ),
               actionButton(
                 inputId = "submit_query",
                 label = "Submit query",
                 icon = icon("play")
               ),
             ),
             gt_output("table_query")
           )
  ),
  
  ### PAGE 4 ###
  tabPanel("LLM Query",
           page_sidebar(
             title = "Bank database",
             sidebar = sidebar(
               chat_ui("chat"),
               width = 400
             ),
             card(
               full_screen = TRUE,
               card_header("Query result"),
               gt_output("llm_table")
             ),
           ),
  ),
  nav_spacer(),
  tabPanel("Citations", 
           h3("References"),
           tags$ul(
             tags$li("Wickham, H., Cheng, J., & Jacobs, A. (2025). ellmer: Chat with Large Language Models. R package version 0.1.1. Retrieved from ", 
                     tags$a(href = "https://ellmer.tidyverse.org", "https://ellmer.tidyverse.org", target = "_blank")),
             tags$li(tags$a("Joe Cheng - Shiny x AI - YouTube", 
                            href = "https://www.youtube.com/watch?v=AP8BWGhCRZc", target = "_blank")),
             tags$li("Iannone, R., Cheng, J., Schloerke, B., Hughes, E., Lauer, A., Seo, J., Brevoort, K., & Roy, O. (2025). gt: Easily Create Presentation-Ready Display Tables. R package version 0.11.1.9000. Retrieved from ", 
                     tags$a(href = "https://gt.rstudio.com", "https://gt.rstudio.com", target = "_blank")),
             tags$li("Chang, W., Cheng, J., Allaire, J.J., Sievert, C., Schloerke, B., Xie, Y., Allen, J., McPherson, J., Dipert, A., & Borges, B. (2025). shiny: Web Application Framework for R. R package version 1.10.0.9000. Retrieved from ", 
                     tags$a(href = "https://shiny.posit.co/", "https://shiny.posit.co/", target = "_blank")),
             tags$li("Mühleisen, H., & Raasveldt, M. (2025). duckdb: DBI Package for the DuckDB Database Management System. R package version 1.2.1. Retrieved from ", 
                     tags$a(href = "https://r.duckdb.org/", "https://r.duckdb.org/", target = "_blank"))
           )
  ),
  
  nav_menu(
    title = "Links",
    align = "right",
    nav_item(link_shiny),
    nav_item(link_posit),
    nav_item(link_github)
  )
  
  
)
  ### END ###


# server function
server <- function(input, output, session) {
  
  ### PAGE 1 ###
  # reactive expression to get the selected table
  selected_table <- eventReactive(
    input$submit, {
      dbGetQuery(con, paste("SELECT * FROM ", input$table))
      }
    )
  # render the selected table
  output$table <- render_gt({
    selected_table() |> 
      gt() |> 
      cols_align(align = "center") |>
      opt_interactive(
        active = TRUE,
        use_pagination = TRUE,
        use_pagination_info = TRUE,
        use_sorting = TRUE,
        use_search = TRUE,
        use_filters = TRUE,
        use_resizers = FALSE,
        use_highlight = TRUE,
        use_compact_mode = FALSE,
        use_text_wrapping = TRUE,
        use_page_size_select = FALSE,
        page_size_default = 25,
        page_size_values = c(10, 25, 50, 100),
        pagination_type = c("numbers", "jump", "simple"),
        height = "auto"
      )
    })
  
  ### PAGE 2 ###
  premade_query <- eventReactive(
    input$submit_premade_query,
    {
      dbGetQuery(con, input$premade_query)
    }
  )
  # output premade query
  output$premade_query <- renderText({
    input$premade_query
  })
  # render table for premade query
  output$table_premade_query <- render_gt({
    premade_query() |> 
      gt() |> 
      cols_align(align = "center") |>
      opt_interactive(
        active = TRUE,
        use_pagination = TRUE,
        use_pagination_info = TRUE,
        use_sorting = TRUE,
        use_search = TRUE,
        use_filters = TRUE,
        use_resizers = FALSE,
        use_highlight = TRUE,
        use_compact_mode = FALSE,
        use_text_wrapping = TRUE,
        use_page_size_select = FALSE,
        page_size_default = 25,
        page_size_values = c(10, 25, 50, 100),
        pagination_type = c("numbers", "jump", "simple"),
        height = "auto"
      )
  })
  
  ### PAGE 3 ###
  submit_query <- eventReactive(
    input$submit_query,
    {
      dbGetQuery(con, input$query)
    }
  )
  output$table_query <- render_gt({
    submit_query() |> 
      gt() |> 
      cols_align(align = "center") |>
      opt_interactive(
        active = TRUE,
        use_pagination = TRUE,
        use_pagination_info = TRUE,
        use_sorting = TRUE,
        use_search = TRUE,
        use_filters = TRUE,
        use_resizers = FALSE,
        use_highlight = TRUE,
        use_compact_mode = FALSE,
        use_text_wrapping = TRUE,
        use_page_size_select = FALSE,
        page_size_default = 25,
        page_size_values = c(10, 25, 50, 100),
        pagination_type = c("numbers", "jump", "simple"),
        height = "auto"
      )
  })
  
  ### PAGE 4 ###
  
  # 🔄 Reactive state/computation --------------------------------------------
  
  current_title <- reactiveVal(NULL)
  current_query <- reactiveVal("")
  
  # This object must always be passed as the `.ctx` argument to query(), so that
  # tool functions can access the context they need to do their jobs; in this
  # case, the database connection that query() needs.
  ctx <- list(con = con)
  
  # The reactive data frame. Either returns the entire dataset, or filtered by
  # whatever Sidebot decided.
  bank_data <- reactive({
    sql <- current_query()
    if (is.null(sql) || sql == "") {
      sql <- "SELECT * FROM bank;"
    }
    dbGetQuery(con, sql)
  })
  
  
  # 🏷️ Header outputs --------------------------------------------------------
  
  output$show_title <- renderText({
    current_title()
  })
  
  output$show_query <- renderText({
    current_query()
  })

  # ✨ Sidebot ✨ -------------------------------------------------------------
  
  append_output <- function(...) {
    txt <- paste0(...)
    shinychat::chat_append_message(
      "chat",
      list(role = "assistant", content = txt),
      chunk = TRUE,
      operation = "append",
      session = session
    )
  }
  
  #' Modifies the data presented in the data dashboard, based on the given SQL
  #' query, and also updates the title.
  #' @param query A DuckDB SQL query; must be a SELECT statement.
  #' @param title A title to display at the top of the data dashboard,
  #'   summarizing the intent of the SQL query.
  update_dashboard <- function(query, title) {
    append_output("\n```sql\n", query, "\n```\n\n")
    
    tryCatch(
      {
        # Try it to see if it errors; if so, the LLM will see the error
        dbGetQuery(con, query)
      },
      error = function(err) {
        append_output("> Error: ", conditionMessage(err), "\n\n")
        stop(err)
      }
    )
    
    if (!is.null(query)) {
      current_query(query)
    }
    if (!is.null(title)) {
      current_title(title)
    }
  }
  
  
  query <- function(query) {
    # Do this before query, in case it errors
    append_output("\n```sql\n", query, "\n```\n\n")
    
    tryCatch(
      {
        df <- dbGetQuery(con, query)
      },
      error = function(e) {
        append_output("> Error: ", conditionMessage(e), "\n\n")
        stop(e)
      }
    )
    
    tbl_gt <- df |> 
      gt() |> 
      cols_align(align = "center") |>
      opt_interactive(
        active = TRUE,
        use_pagination = TRUE,
        use_pagination_info = TRUE,
        use_sorting = TRUE,
        use_search = TRUE,
        use_filters = TRUE,
        use_resizers = FALSE,
        use_highlight = TRUE,
        use_compact_mode = FALSE,
        use_text_wrapping = TRUE,
        use_page_size_select = FALSE,
        page_size_default = 25,
        page_size_values = c(10, 25, 50, 100),
        pagination_type = c("numbers", "jump", "simple"),
        height = "auto"
      )
      
    output$llm_table <- render_gt({
      tbl_gt
    })
    
    append_output(capture.output(tbl_gt), "\n\n")
  }
  

  # Preload the conversation with the system prompt. These are instructions for
  # the chat model, and must not be shown to the end user.
  # chat <- ellmer::chat_ollama(model = "llama3.2", system_prompt = system_prompt_str)
  chat <- ellmer::chat_groq(
    system_prompt = system_prompt_str,
    api_key = Sys.getenv("GROQ_API_KEY"),
    model = "DeepSeek-R1-Distill-Llama-70B"
  )
  chat$register_tool(tool(
    update_dashboard,
    "Modifies the data presented in the gt table, based on the given SQL query.",
    query = type_string("A DuckDB SQL query; must be a SELECT statement."),
    # title = type_string("A title to display at the top of the data dashboard, summarizing the intent of the SQL query.")
  ))
  chat$register_tool(tool(
    query,
    "Perform a SQL query on the data, and return the results in the gt table",
    query = type_string("A DuckDB SQL query; must be a SELECT statement.")
  ))
  
  # Prepopulate the chat UI with a welcome message that appears to be from the
  # chat model (but is actually hard-coded). This is just for the user, not for
  # the chat model to see.
  chat_append("chat", greeting)
  # Handle user input
  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    chat_append("chat", stream)
  })



### END ###
}
  

shinyApp(ui = ui, server = server)