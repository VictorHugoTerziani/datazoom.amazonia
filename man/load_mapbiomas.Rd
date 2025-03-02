% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mapbiomas.R
\name{load_mapbiomas}
\alias{load_mapbiomas}
\title{MAPBIOMAS - The Annual Land Cover and Use Mapping Project in Brazil}
\usage{
load_mapbiomas(
  dataset = NULL,
  raw_data = FALSE,
  geo_level = "municipality",
  language = "eng",
  cover_level = 1
)
}
\arguments{
\item{dataset}{A dataset name ("mapbiomas_cover", "mapbiomas_transition", "mapbiomas_irrigation", "mapbiomas_deforestation_regeneration", "mapbiomas_grazing_quality", or "mapbiomas_mining")}

\item{raw_data}{A \code{boolean} setting the return of raw or processed data}

\item{geo_level}{A \code{string} that defines the geographic level of the data. For datasets "mapbiomas_cover" and "mapbiomas_transition", can be "municipality" or "state" (faster download) for datasets. For dataset "mapbiomas_mining", can be "biome" or "indigenous_land"}

\item{language}{A \code{string} that indicates in which language the data will be returned. Currently, only Portuguese ("pt") and English ("eng") are supported.}

\item{cover_level}{A \code{numeric} or \code{string} that indicates the cover aggregation level. Can be "0", "1", "2", "3", "4", or "none", which means no aggregation. Aggregation only supported for "mapbiomas_cover" and "mapbiomas_grazing_quality" datasets.}
}
\value{
A \code{tibble} with the selected data.
}
\description{
Loads information about land cover and use
}
\examples{
\dontrun{
# download treated data from mapbiomas_grazing_quality
treated_mapbiomas_grazing <- load_mapbiomas(
  dataset = "mapbiomas_grazing_quality",
  raw_data = FALSE, geo_level = "municipality",
  language = "pt"
)
}

}
