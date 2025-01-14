% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dummy_data.R
\name{dummy_data}
\alias{dummy_data}
\title{Dummy data}
\usage{
dummy_data(
  output = c("list", "SingleCellExperiment", "Seurat", "InMemoryAnnData", "HDF5AnnData"),
  n_obs = 10L,
  n_var = 20L,
  n_obsm = n_obs\%/\%2,
  n_varm = n_obsm,
  density = 0.1,
  ...
)
}
\arguments{
\item{output}{Object type to output, one of "list", "SingleCellExperiment",
or "Seurat".}

\item{n_obs}{Number of observations to generate.}

\item{n_var}{Number of variables to generate.}

\item{n_obsm}{Number of embedding dimensions.}

\item{n_varm}{Number of loading dimensions.}

\item{density}{Of the matrices on a scale from 0-1.
Passed to \link[Matrix]{rsparsematrix}.}

\item{...}{Additional arguments passed to subfunctions
(determined by \code{output}).}
}
\value{
Object containing the generated dataset as defined by \code{output}
}
\description{
Generate a dummy dataset in a selected format.
}
\examples{
dummy <- dummy_data("InMemoryAnnData")
}
