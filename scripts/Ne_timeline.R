library(ggplot2)
library(dplyr)

mu <- 1.25e-8
inflation <- 1.82

# Datos SH calibrados (bootstrap means)
sh_data <- data.frame(
  label    = c("FemurXIII", "Femur fragment", "Molar L35", "Scapula"),
  age_ka   = c(430, 430, 430, 430),
  H_cal    = c(0.002153, 0.001685, 0.002198, 0.001075) / inflation,
  H_lo     = c(0.001989, 0.001355, 0.002119, 0.001030) / inflation,
  H_hi     = c(0.002250, 0.001970, 0.002274, 0.001115) / inflation,
  group    = "Sima de los Huesos"
)
sh_data$Ne     <- sh_data$H_cal / (4 * mu * (1 - sh_data$H_cal))
sh_data$Ne_lo  <- sh_data$H_lo  / (4 * mu * (1 - sh_data$H_lo))
sh_data$Ne_hi  <- sh_data$H_hi  / (4 * mu * (1 - sh_data$H_hi))

# Referencias publicadas
refs <- data.frame(
  label   = c("Vindija 33.19", "Denisova D17", "Ust'-Ishim", "H. sapiens AFR"),
  age_ka  = c(44, 50, 45, 0),
  H_cal   = c(0.000700, 0.000500, 0.001000, 0.001300),
  H_lo    = c(NA, NA, NA, NA),
  H_hi    = c(NA, NA, NA, NA),
  group   = c("Late Neandertal", "Denisovan", "Early modern human", "Modern human (AFR)")
)
refs$Ne    <- refs$H_cal / (4 * mu * (1 - refs$H_cal))
refs$Ne_lo <- NA
refs$Ne_hi <- NA

all_data <- bind_rows(sh_data, refs)

# Colores por grupo
cols <- c(
  "Sima de los Huesos"  = "#185FA5",
  "Late Neandertal"     = "#A32D2D",
  "Denisovan"           = "#854F0B",
  "Early modern human"  = "#0F6E56",
  "Modern human (AFR)"  = "#534AB7"
)
shapes <- c(
  "Sima de los Huesos"  = 21,
  "Late Neandertal"     = 22,
  "Denisovan"           = 23,
  "Early modern human"  = 24,
  "Modern human (AFR)"  = 25
)

p <- ggplot(all_data, aes(x = age_ka, y = Ne, color = group, fill = group, shape = group)) +

  # Banda temporal SH
  annotate("rect", xmin = 420, xmax = 440, ymin = 0, ymax = 32000,
           fill = "#E6F1FB", alpha = 0.5) +
  annotate("text", x = 430, y = 31000, label = "~430 ka",
           size = 3, color = "#185FA5", fontface = "italic") +

  # Barras de error SH
  geom_errorbar(
    data = filter(all_data, group == "Sima de los Huesos"),
    aes(ymin = Ne_lo, ymax = Ne_hi),
    width = 8, linewidth = 0.5, color = "#185FA5"
  ) +

  # Puntos
  geom_point(size = 4, stroke = 0.6) +

  # Etiquetas
  ggrepel::geom_text_repel(
    aes(label = label),
    size = 3, show.legend = FALSE,
    min.segment.length = 0.2,
    box.padding = 0.4,
    color = "grey30",
    fontface = "italic"
  ) +

  scale_x_reverse(
    limits = c(460, -20),
    breaks = c(400, 300, 200, 100, 50, 10, 0),
    labels = c("400", "300", "200", "100", "50", "10", "0")
  ) +
  scale_y_continuous(
    limits = c(0, 32000),
    breaks = seq(0, 30000, by = 5000),
    labels = scales::comma
  ) +
  scale_color_manual(values = cols, name = NULL) +
  scale_fill_manual(values  = cols, name = NULL) +
  scale_shape_manual(values = shapes, name = NULL) +

  labs(
    title    = "Effective population size across archaic and modern hominins",
    subtitle = "SH values calibrated (pipeline inflation factor 1.82x)  .  error bars = 95% CI bootstrap  .  mu = 1.25e-8",
    x        = "Age (ka BP)",
    y        = expression(paste("Effective population size (", N[e], ")"))
  ) +

  theme_classic(base_size = 12) +
  theme(
    plot.background  = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    plot.title    = element_text(size = 12, face = "bold", color = "black"),
    plot.subtitle = element_text(size =  9, color = "grey40"),
    axis.text     = element_text(size = 10, color = "black"),
    axis.title    = element_text(size = 11, color = "black"),
    legend.position = c(0.75, 0.75),
    legend.background = element_rect(fill = "white", color = "grey85", linewidth = 0.3),
    legend.text   = element_text(size = 9),
    panel.grid.major.y = element_line(color = "grey92", linewidth = 0.3)
  )

# ggrepel requiere instalacion
if (!requireNamespace("ggrepel", quietly = TRUE)) {
  install.packages("ggrepel", repos = "https://cloud.r-project.org")
}
library(ggrepel)

ggsave("~/PopSize/results/Ne_timeline.pdf",
       p, width = 10, height = 6, device = "pdf", bg = "white")
ggsave("~/PopSize/results/Ne_timeline.png",
       p, width = 10, height = 6, dpi = 300, bg = "white")

cat("✓ Ne timeline guardado\n")
