#' @title HDF5AnnData
#'
#' @description
#' Implementation of an in memory AnnData object.
#' @returns An \link[anndataR]{HDF5AnnData} object.
HDF5AnnData <- R6::R6Class("HDF5AnnData", # nolint
  inherit = AbstractAnnData,
  private = list(
    .h5obj = NULL,
    .n_obs = NULL,
    .n_var = NULL,
    .obs_names = NULL,
    .var_names = NULL,
    .obsm = NULL,
    .varm = NULL,
    .obsp = NULL,
    .varp = NULL
  ),
  active = list(
    #' @field X The X slot
    X = function(value) {
      if (missing(value)) {
        # trackstatus: class=HDF5AnnData, feature=get_X, status=done
        read_h5ad_element(private$.h5obj, "/X")
      } else {
        # trackstatus: class=HDF5AnnData, feature=set_X, status=done
        value <- private$.validate_matrix(value, "X")
        write_h5ad_element(value, private$.h5obj, "/X")
      }
    },
    #' @field layers The layers slot. Must be NULL or a named list
    #'   with with all elements having the dimensions consistent with
    #'   `obs` and `var`.
    layers = function(value) {
      if (missing(value)) {
        # trackstatus: class=HDF5AnnData, feature=get_layers, status=done
        read_h5ad_element(private$.h5obj, "layers")
      } else {
        # trackstatus: class=HDF5AnnData, feature=set_layers, status=done
        value <- private$.validate_aligned_mapping(
          value,
          "layers",
          c(self$n_obs(), self$n_var()),
          expected_rownames = rownames(self),
          expected_colnames = colnames(self)
        )
        write_h5ad_element(value, private$.h5obj, "/layers")
      }
    },
    #' @field obsm The obsm slot. Must be `NULL` or a named list with
    #'   with all elements having the same number of rows as `obs`.
    obsm = function(value) {
      if (missing(value)) {
        # trackstatus: class=HDF5AnnData, feature=get_obsm, status=done
        read_h5ad_element(private$.h5obj, "obsm")
      } else {
        # trackstatus: class=HDF5AnnData, feature=set_obsm, status=done
        value <- private$.validate_aligned_mapping(
          value,
          "obsm",
          c(self$n_obs()),
          expected_rownames = rownames(self)
        )
        write_h5ad_element(value, private$.h5obj, "/obsm")
      }
    },
    #' @field varm The varm slot. Must be `NULL` or a named list with
    #'   with all elements having the same number of rows as `var`.
    varm = function(value) {
      if (missing(value)) {
        # trackstatus: class=HDF5AnnData, feature=get_varm, status=done
        read_h5ad_element(private$.h5obj, "varm")
      } else {
        # trackstatus: class=HDF5AnnData, feature=set_varm, status=done
        value <- private$.validate_aligned_mapping(
          value,
          "varm",
          c(self$n_var()),
          expected_rownames = colnames(self)
        )
        write_h5ad_element(value, private$.h5obj, "/varm")
      }
    },
    #' @field obsp The obsp slot. Must be `NULL` or a named list with
    #'   with all elements having the same number of rows and columns as `obs`.
    obsp = function(value) {
      if (missing(value)) {
        # trackstatus: class=HDF5AnnData, feature=get_obsp, status=done
        read_h5ad_element(private$.h5obj, "obsp")
      } else {
        # trackstatus: class=HDF5AnnData, feature=set_obsp, status=done
        value <- private$.validate_aligned_mapping(
          value,
          "obsp",
          c(self$n_obs(), self$n_obs()),
          expected_rownames = rownames(self),
          expected_colnames = rownames(self)
        )
        write_h5ad_element(value, private$.h5obj, "/obsp")
      }
    },
    #' @field varp The varp slot. Must be `NULL` or a named list with
    #'   with all elements having the same number of rows and columns as `var`.
    varp = function(value) {
      if (missing(value)) {
        # trackstatus: class=HDF5AnnData, feature=get_varp, status=done
        read_h5ad_element(private$.h5obj, "varp")
      } else {
        # trackstatus: class=HDF5AnnData, feature=set_varp, status=done
        value <- private$.validate_aligned_mapping(
          value,
          "varp",
          c(self$n_var(), self$n_var()),
          expected_rownames = colnames(self),
          expected_colnames = colnames(self)
        )
        write_h5ad_element(value, private$.h5obj, "/varp")
      }
    },

    #' @field obs The obs slot
    obs = function(value) {
      if (missing(value)) {
        # trackstatus: class=HDF5AnnData, feature=get_obs, status=done
        read_h5ad_element(private$.h5obj, "/obs", include_index = FALSE)
      } else {
        # trackstatus: class=HDF5AnnData, feature=set_obs, status=done
        value <- private$.validate_obsvar_dataframe(value, "obs")
        write_h5ad_element(
          value,
          private$.h5obj,
          "/obs",
          index = self$obs_names
        )
      }
    },
    #' @field var The var slot
    var = function(value) {
      if (missing(value)) {
        # trackstatus: class=HDF5AnnData, feature=get_var, status=done
        read_h5ad_element(private$.h5obj, "/var", include_index = FALSE)
      } else {
        # trackstatus: class=HDF5AnnData, feature=set_var, status=done
        value <- private$.validate_obsvar_dataframe(value, "var")
        write_h5ad_element(
          value,
          private$.h5obj,
          "/var",
          index = self$var_names
        )
      }
    },
    #' @field obs_names Names of observations
    obs_names = function(value) {
      if (missing(value)) {
        # trackstatus: class=HDF5AnnData, feature=get_obs_names, status=done
        # obs names are cached to avoid reading all of obs whenever they are
        # accessed
        if (is.null(private$.obs_names)) {
          private$.obs_names <- read_h5ad_data_frame_index(private$.h5obj, "obs")
        }
        private$.obs_names
      } else {
        # trackstatus: class=HDF5AnnData, feature=set_obs_names, status=done
        value <- private$.validate_obsvar_names(value, "obs")
        write_h5ad_data_frame_index(value, private$.h5obj, "obs", "_index")
        private$.obs_names <- value
      }
    },
    #' @field var_names Names of variables
    var_names = function(value) {
      # TODO: directly write to and read from /var/_index
      if (missing(value)) {
        # trackstatus: class=HDF5AnnData, feature=get_var_names, status=done
        # var names are cached to avoid reading all of var whenever they are
        # accessed
        if (is.null(private$.var_names)) {
          private$.var_names <- read_h5ad_data_frame_index(private$.h5obj, 
                                                           "var")
        }
        private$.var_names
      } else {
        # trackstatus: class=HDF5AnnData, feature=set_var_names, status=done
        value <- private$.validate_obsvar_names(value, "var")
        write_h5ad_data_frame_index(value, private$.h5obj, "var", "_index")
        private$.var_names <- value
      }
    }
  ),
  public = list(
    #' @description HDF5AnnData constructor
    #'
    #' @param file The filename (character) of the `.h5ad` file.
    #'  If this file does not exist yet, `obs_names` and `var_names` 
    #'  must be provided.
    #' @param obs_names A vector of unique identifiers
    #'   used to identify each row of `obs` and to act as an index into the
    #'   observation dimension of the AnnData object. The length of `obs_names`
    #'   defines the observation dimension of the AnnData object.
    #' @param var_names A vector of unique identifiers used to identify each row
    #'   of `var` and to act as an index into the variable dimension of the
    #'   AnnData object. The length of `var_names` defines the variable
    #'   dimension of the AnnData object.
    #' @param X Either `NULL` or a observation × variable matrix with
    #'   dimensions consistent with `obs` and `var`.
    #' @param layers Either `NULL` or a named list, where each element is an
    #'   observation × variable matrix with dimensions consistent with `obs` and
    #'   `var`.
    #' @param obs Either `NULL` or a `data.frame` with columns containing
    #'   information about observations. If `NULL`, an `n_obs`×0 data frame will
    #'   automatically be generated.
    #' @param var Either `NULL` or a `data.frame` with columns containing
    #'   information about variables. If `NULL`, an `n_var`×0 data frame will
    #'   automatically be generated.
    #' @param obsm The obsm slot is used to store multi-dimensional annotation
    #'   arrays. It must be either `NULL` or a named list, where each element 
    #'   is a matrix with `n_obs` rows and an arbitrary number of columns.
    #' @param varm The varm slot is used to store multi-dimensional annotation
    #'   arrays. It must be either `NULL` or a named list, where each element
    #'    is a matrix with `n_var` rows and an arbitrary number of columns.
    #' @param obsp The obsp slot is used to store sparse multi-dimensional
    #'   annotation arrays. It must be either `NULL` or a named list, where each
    #'   element is a sparse matrix where each dimension has length `n_obs`.
    #' @param varp The varp slot is used to store sparse multi-dimensional
    #'   annotation arrays. It must be either `NULL` or a named list, where each
    #'   element is a sparse matrix where each dimension has length `n_var`.
    #'
    #' @details
    #' The constructor creates a new HDF5 AnnData interface object. This can
    #' either be used to either connect to an existing `.h5ad` file or to
    #' create a new one. To create a new file both `obs_names` and `var_names`
    #' must be specified. In both cases, any additional slots provided will be
    #' set on the created object. This will cause data to be overwritten if the
    #' file already exists.
    initialize = function(file,
                          obs_names = NULL,
                          var_names = NULL,
                          X = NULL,
                          obs = NULL,
                          var = NULL,
                          layers = NULL,
                          obsm = NULL,
                          varm = NULL,
                          obsp = NULL,
                          varp = NULL) {
      if (!requireNamespace("rhdf5", quietly = TRUE)) {
        stop("The HDF5 interface requires the 'rhdf5' package to be installed")
      }

      if (!file.exists(file)) {
        # Check obs_names and var_names have been provided
        if (is.null(obs_names)) {
          stop("When creating a new .h5ad file, `obs_names` must be defined.")
        }
        if (is.null(var_names)) {
          stop("When creating a new .h5ad file, `var_names` must be defined.")
        }

        # Create an empty H5AD using the provided obs/var names
        write_empty_h5ad(file, obs_names, var_names)

        # Set private object slots
        private$.h5obj <- file
        private$.n_obs <- length(obs_names)
        private$.n_var <- length(var_names)
        private$.obs_names <- obs_names
        private$.var_names <- var_names
      } else {
        # Check the file is a valid H5AD
        attrs <- rhdf5::h5readAttributes(file, "/")

        if (!all(c("encoding-type", "encoding-version") %in% names(attrs))) {
          stop(
            "H5AD encoding information is missing. ",
            "This file may have been created with Python anndata<0.8.0."
          )
        }

        # Set the file path
        private$.h5obj <- file

        # If obs or var names have been provided update those
        if (!is.null(obs_names)) {
          self$obs_names <- obs_names
        }

        if (!is.null(var_names)) {
          self$var_names <- var_names
        }
      }

      # Update remaining slots
      if (!is.null(X)) {
        self$X <- X
      }

      if (!is.null(obs)) {
        self$obs <- obs
      }

      if (!is.null(var)) {
        self$var <- var
      }

      if (!is.null(layers)) {
        self$layers <- layers
      }

      if (!is.null(obsm)) {
        self$obsm <- obsm
      }

      if (!is.null(varm)) {
        self$varm <- varm
      }

      if (!is.null(obsp)) {
        self$obsp <- obsp
      }

      if (!is.null(varp)) {
        self$varp <- varp
      }
    },

    #' @description Number of observations in the AnnData object
    n_obs = function() {
      if (is.null(private$.n_obs)) {
        private$.n_obs <- length(self$obs_names)
      }
      private$.n_obs
    },

    #' @description Number of variables in the AnnData object
    n_var = function() {
      if (is.null(private$.n_var)) {
        private$.n_var <- length(self$var_names)
      }
      private$.n_var
    }
  )
)

#' Convert an AnnData object to an HDF5AnnData object
#'
#' This function takes an AnnData object and converts it to an HDF5AnnData
#' object, loading all fields into memory.
#'
#' @param adata An AnnData object to be converted to HDF5AnnData.
#' @param file The filename (character) of the `.h5ad` file.
#'
#' @return An HDF5AnnData object with the same data as the input AnnData
#'   object.
#'
#' @export
#'
#' @examples
#' adata <- dummy_data("InMemoryAnnData")
#' adata2 <- to_HDF5AnnData(adata, "test.h5ad")
#' adata2
#' # remove file
#' file.remove("test.h5ad")
to_HDF5AnnData <- function(adata, file) { # nolint
  stopifnot(
    inherits(adata, "AbstractAnnData")
  )
  HDF5AnnData$new(
    file = file,
    X = adata$X,
    obs = adata$obs,
    var = adata$var,
    obsm = adata$obsm,
    varm = adata$varm,
    obs_names = adata$obs_names,
    var_names = adata$var_names,
    layers = adata$layers,
    obsp = adata$obsp,
    varp = adata$varp
  )
}
