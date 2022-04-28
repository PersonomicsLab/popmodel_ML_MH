library(ggplot2)
# library(ggbeeswarm)
source("~/Documents/Personomics_Research_Group/WAPIAW_2/figure_plotting/config.r")
source("~/Documents/Personomics_Research_Group/WAPIAW_2/figure_plotting/utils.r")

# default input ploting csv file
data <- read.csv("~/Documents/Personomics_Research_Group/WAPIAW_2/figure_plotting/subtypes/plotting.csv")

# default output file (png and optionally pdf) name (without file extension)
fname <- "~/Documents/Personomics_Research_Group/WAPIAW_2/figure_plotting/all_plots/subtypes_plot"
print(fname)

# take (optional) input plotting csv file and output file from command line call
#args <- commandArgs(trailingOnly=T)
#if (length(args)>=1) {
#	data <- read.csv(args[1])
#} else if (length(args)>=2) {
#	fname <- args[2]
#}

# Whether or not to plot an pdf along with png
plot_pdf <- F

# Data will be plotted in the order below, from the bottom to the top
# Also, if you find your categories too long, give them a shorter label here
data$method <- factor(
    data$method,
    levels = c("Dadi", "Rest", "All Features",
	"Rest & Subtype 1", "Rest & Subtype 2", "Rest & Subtype 3",
	"All & Subtype 1", "All & Subtype 2", "All & Subtype 3"),
    labels = c("Rest (Dadi et al. 2021)", "Rest (replication)", "All Features",
	"Rest & Subtype 1", "Rest & Subtype 2", "Rest & Subtype 3",
	"All & Subtype 1", "All & Subtype 2", "All & Subtype 3"),
)

# Aesthetics
fig_w <- 7  # Width
fig_h <- 3.8  # Height
n_row <- 1  # Number of rows (each target will be plotted in one panel)
n_col <- NULL  # Number of columns
method_font_size <- 10  # Font size of the labels on the left
r2_font_size <- 10  # Font size of the R2 tick labels
mR2_font_size <- 2.55  # Font size of the mean R2 value on the violin plot
dodge <- 0.6  # Distance between violin plots and the bottom axis

# and many more you could change in the ggplot() function


#######################################################################

data$fold <- factor(data$fold)

# Specify model_type (not used in plotting)
data$model_type <- "full MRI"
data$model_type[grepl(",", data$modality)] <- "multi-modal"
data$model_type[data$modality == "sMRI"] <- "mono-modal"
data$model_type[data$modality == "dMRI"] <- "mono-modal"
data$model_type[data$modality == "fMRI"] <- "mono-modal"
data$model_type <- factor(data$model_type,
                          levels = c("full MRI", "multi-modal", "mono-modal"))

# Format of output numbers
my_fmt <- function(x) {
    n <- 2
    format(round(x, n), nsmall = n, scientific = F)
}

# Select data (only dat1 was used in plotting)
dat1 <- subset(data, model_testing == "validation" &
               Permuted == "no")
dat2 <- subset(data, model_testing != "validation" &
               Permuted == "no")
dat3 <- rbind(dat1, dat2)
dat3$model_testing <- factor(dat3$model_testing,
                            levels = c("generalization", "validation"))

# Color defined in config.r
this_colors <- with(color_cats, c(orange, `blueish green`, blue))

fig <- ggplot(
    data = dat1,
    mapping = aes(y = r2_score,
                  x = method,
                  fill = target,
                  color = target)) +
    # organize the panels by "target"
    facet_wrap(.~target, nrow = n_row, ncol = n_col, scale = "free_x") +
    geom_violin(width = 1.,
               position = position_dodge(width = dodge),
        trim = F, alpha = 0.6, show.legend = T) +
    scale_y_continuous(labels = my_fmt) +
    scale_shape_manual(values = c(21, 22, 23)) +
    stat_summary(
       fun = mean, geom = "point", size = 1.5,
       shape = 21,
       fill = "white",
       show.legend = F,
       position = position_dodge(width = dodge)) +
    stat_summary(
      data = dat2,
      fun = mean, geom = "point", size = 1.5,
      fill = 'white', shape = 24,
      position = position_dodge(width = 0.4), show.legend = F) +
    stat_summary(
        geom = "text",
        mapping = aes(label = sprintf("%1.2f", ..y..)),
        fun = mean, size = mR2_font_size,
           show.legend = FALSE,
        color = "black",
        hjust = -0.04,
        vjust = 2.6,
        position = position_dodge(width = dodge)) +
    scale_color_manual(values = this_colors) +
    scale_fill_manual(values = this_colors) +
    guides(fill = F, linetype = F, alpha = F, color = F) +
    theme_minimal() +
    theme(legend.position = c(0.1, 1.15)) +
    coord_flip() +
    theme(text = element_text(family = "Helvetica", size = 12),
            legend.text = element_text(size = 10),
            legend.title = element_text(size = 10),
            panel.spacing.x = unit(0.03, "npc"),
            panel.grid.major.y = element_line(size = 1.5),
            strip.text.x = element_text(hjust = 0.5),
            axis.text.x = element_text(size = r2_font_size),  # R^2 value
            axis.text.y = element_text(size = method_font_size),  # Categories
            axis.title.y = element_blank()) +
    ylab(bquote(R^2%+-%~scriptstyle("CV-based uncertainty estimates"))) + # nolint
    ggtitle("Approximation Quality on Heterogeneous Subtypes") +
    labs(tag = expression("Using" * " " *symbol("\257") * " " * "to predict:")) + # nolint
    theme(plot.tag.position = c(0.07, 0.89),
        plot.tag = element_text(size = 9.5),
        plot.title = element_text(hjust = 0.5))
    # theme(panel.spacing = unit(5, "lines")) # nolint

# print(fig)

my_ggsave(fname = fname, plot = fig, savepdf = plot_pdf, height = fig_h, width = fig_w)
