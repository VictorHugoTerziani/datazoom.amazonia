#' @title MAPBIOMAS - The Annual Land Cover and Use Mapping Project in Brazil
#'
#' @description Loads information about land cover and use
#'
#' @param dataset A dataset name ("mapbiomas_cover", "mapbiomas_transition", "mapbiomas_irrigation", "mapbiomas_deforestation_regeneration", "mapbiomas_grazing_quality", or "mapbiomas_mining")
#' @param raw_data A \code{boolean} setting the return of raw or processed data
#' @param geo_level A \code{string} that defines the geographic level of the data. For datasets "mapbiomas_cover" and "mapbiomas_transition", can be "municipality" or "state" (faster download) for datasets. For dataset "mapbiomas_mining", can be "biome" or "indigenous_land"
#' @param language A \code{string} that indicates in which language the data will be returned. Currently, only Portuguese ("pt") and English ("eng") are supported.
#' @param cover_level A \code{numeric} or \code{string} that indicates the cover aggregation level. Can be "0", "1", "2", "3", "4", or "none", which means no aggregation. Aggregation only supported for "mapbiomas_cover" and "mapbiomas_grazing_quality" datasets.
#' @return A \code{tibble} with the selected data.
#'
#' @examples
#' \dontrun{
#' # download treated data from mapbiomas_grazing_quality
#' treated_mapbiomas_grazing <- load_mapbiomas(
#'   dataset = "mapbiomas_grazing_quality",
#'   raw_data = FALSE, geo_level = "municipality",
#'   language = "pt"
#' )
#' }
#'
#' @importFrom magrittr %>%
#' @export


load_mapbiomas <- function(dataset = NULL, raw_data = FALSE, geo_level = "municipality",
                           language = "eng", cover_level = 1) {

  # Checking for googledrive package (in Suggests) only for mapbiomas_transition dataset

  if (!requireNamespace("googledrive", quietly = TRUE) &
    dataset %in% c("mapbiomas_cover", "mapbiomas_transition") &
    geo_level == "municipality") {
    stop(
      "Package \"googledrive\" must be installed to use this function.",
      call. = FALSE
    )
  }

  ###########################
  ## Bind Global Variables ##
  ###########################
  survey <- link <- x1985 <- x2019 <- NULL
  ano <- bioma <- category <- cidade <- city <- class_id <- country <- estado <- feature_id <- group <- terra_indigena <- NULL
  id <- indigenous_land <- level_2 <- level_3 <- name_pt_br <- pais <- x2020 <- NULL
  territory_id <- municipality <- state <- year <- value <- NULL
  x1985_to_1986 <- x2018_to_2019 <- x1988 <- x2017 <- x2000 <- x2010 <- x2018 <- biome <- level_1 <- NULL


  #############################
  ## Define Basic Parameters ##
  #############################

  param <- list()
  param$dataset <- dataset
  param$geo_level <- geo_level
  param$language <- language
  param$raw_data <- raw_data
  param$cover_level <- cover_level

  param$survey_name <- datasets_link() %>%
    dplyr::filter(dataset == param$dataset) %>%
    dplyr::select(survey) %>%
    unlist()

  param$url <- datasets_link() %>%
    dplyr::filter(dataset == param$dataset) %>%
    dplyr::select(link) %>%
    unlist()

  ## Dataset

  if (is.null(param$dataset)) {
    stop("Missing Dataset!")
  }
  if (is.null(param$raw_data)) {
    stop("Missing TRUE/FALSE for Raw Data")
  }

  sheets <- tibble::tribble(
    ~dataset, ~geo_level, ~sheet,
    "mapbiomas_cover", "any", "LAND COVER",
    "mapbiomas_transition", "any", "TRANSITIONS",
    "mapbiomas_deforestation_regeneration", "any", "BD Colecao 5.0(h) - Hectares",
    "mapbiomas_irrigation", "any", "BD_IRRIGACAO",
    "mapbiomas_grazing_quality", "any", "BD_Qualidade",
    "mapbiomas_mining", "country", "BR",
    "mapbiomas_mining", "state", "UF",
    "mapbiomas_mining", "biome", "BIOME",
    "mapbiomas_mining", "municipality", "MUN",
    "mapbiomas_mining", "indigenous_land", "TI"
  )

  sheet <- sheets %>%
    dplyr::filter(
      dataset == param$dataset,
      geo_level %in% c(param$geo_level, "any")
    ) %>%
    dplyr::select(sheet) %>%
    unlist()

  #################
  ## Downloading ##
  #################

  dat <- external_download(
    dataset = param$dataset,
    source = "mapbiomas",
    geo_level = param$geo_level,
    sheet = sheet
  )

  dat <- dat %>%
    janitor::clean_names() %>%
    tibble::as_tibble() %>%
    dplyr::mutate_if(is.character, function(var) {
      stringi::stri_trans_general(str = var, id = "Latin-ASCII")
    })

  if (raw_data == TRUE) {
    return(dat)
  }

  ######################
  ## Data Engineering ##
  ######################

  ## Create Longer Data - Years as a Variable

  dat <- dat %>%
    tidyr::pivot_longer(
      cols = dplyr::starts_with("x"),
      names_to = "year",
      names_prefix = "x",
      values_to = "value"
    )

  # Testing cover_level support
  if (param$dataset == "mapbiomas_grazing_quality" & !(param$cover_level %in% c(1, "1", "none"))) {
    base::message("The \"mapbiomas_grazing_quality\" dataset only supports cover_level 1 or \"none\"")
    param$cover_level <- 1
  }

  if (param$dataset %in% c("mapbiomas_cover", "mapbiomas_grazing_quality") & param$cover_level != "none") {

    ## Aggregating by Cover Level

    dat <- dat %>%
      tidyr::pivot_wider(
        id_cols = dplyr::any_of(c(
          "geo_code", "city",
          "state", "year",
          "biome", "state"
        )),
        names_from = paste0("level_", param$cover_level),
        values_from = value,
        values_fn = sum,
        values_fill = NA
      ) %>%
      janitor::clean_names()
  }

  dat <- dat %>%
    dplyr::select(-dplyr::any_of("category"))

  #################
  ## Translation ##
  #################

  dat_mod <- dat %>%
    dplyr::rename_with(dplyr::recode,
      "name_pt_br" = param$geo_level
    )

  dat_mod <- dat_mod %>%
    dplyr::relocate(dplyr::any_of(c("year", "state", "city", "geo_code", "biome", "indigenous_land")))

  if (param$language == "pt") {
    dat_mod <- dat_mod %>%
      dplyr::rename_with(dplyr::recode,
        "feature_id" = "id",
        "class_id" = "id_classe",
        "group" = "grupo",
        "year" = "ano",
        "value" = "valor",
        "state" = "estado",
        "municipality" = "municipio",
        "city" = "municipio",
        "geo_code" = "cod_municipio",
        "biome" = "bioma",
        "indigenous_land" = "terra_indigena",
      )
  }

  if (param$language == "eng") {
    dat_mod <- dat_mod %>%
      dplyr::rename_with(dplyr::recode,
        "city" = "municipality",
        "geo_code" = "municipality_code",
        "codigobioma" = "biome_code",
        "bioma" = "biome",
        "uf" = "state",
        "cod_tipo_mudanca_n1" = "code_type_change_l1",
        "cod_tipo_mudanca_n2" = "code_type_change_l2",
        "cod_classe_des_ou_reg" = "code_class_def_or_reg",
        "tipo_mudanca_nivel1" = "type_change_level_1",
        "tipo_mudanca_nivel2" = "type_change_level_2",
        "cobertura_nivel_1" = "cover_level_1",
        "cobertura_nivel_2" = "cover_level_2",
        "cobertura_nivel_3" = "cover_level_3",
        "cobertura_nivel_4" = "cover_level_4"
      )
  }

  ####################
  ## Returning Data ##
  ####################

  return(dat_mod)
}
