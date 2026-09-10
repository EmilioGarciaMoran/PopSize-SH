library(ggplot2)

# Puntos reales (calibrados)
data_points <- data.frame(
  age_ka  = c(430, 430, 430, 430, 120, 80, 54, 44, 50),
  Ne      = c(13280, 13016, 6487, 10174, 5000, 2500, 3000, 3000, 1500),
  label   = c("molar_L35", "femurXIII", "scapula", "femur_fragment",
              "D5 (Altai)", "Chagyrskaya 8", "Vindija 33.19",
              "Goyet GN1", "Denisova D17"),
  group   = c("SH","SH","SH","SH",
              "Neandertal tardío","Neandertal tardío",
              "Neandertal tardío","Neandertal tardío",
              "Denisovano")
)

# Curva exponencial ilustrativa
# Ne(t) = 3000 + (13000-3000) * exp(-lambda * (430-t))
# Ajuste visual: lambda tal que a t=120 ka Ne~5000
lambda <- -log((5000-3000)/(13000-3000)) / (430-120)
t_seq <- seq(0, 450, by=1)
Ne_curve <- 3000 + (13000-3000) * exp(-lambda * (430 - t_seq))
Ne_curve[t_seq > 430] <- NA

curve_df <- data.frame(age_ka=t_seq, Ne=Ne_curve)

cols <- c("SH" = "#185FA5",
          "Neandertal tardío" = "#A32D2D",
          "Denisovano" = "#854F0B")

shapes <- c("SH"=21, "Neandertal tardío"=22, "Denisovano"=23)

p <- ggplot() +

  # Banda de incertidumbre SH
  annotate("rect", xmin=420, xmax=440, ymin=0, ymax=14500,
           fill="#E6F1FB", alpha=0.5) +

  # Curva exponencial ilustrativa
  geom_line(data=curve_df,
            aes(x=age_ka, y=Ne),
            color="grey50", linewidth=0.8,
            linetype="dashed") +

  # Asíntota
  geom_hline(yintercept=3000, color="#A32D2D",
             linewidth=0.5, linetype="dotted") +
  annotate("text", x=10, y=3200,
           label="Ne minimum (~3,000)", color="#A32D2D",
           size=3, hjust=0, fontface="italic") +

  # Puntos
  geom_point(data=data_points,
             aes(x=age_ka, y=Ne,
                 fill=group, color=group, shape=group),
             size=4, stroke=0.6) +

  # Labels
  ggrepel::geom_text_repel(
    data=data_points,
    aes(x=age_ka, y=Ne, label=label, color=group),
    size=3, show.legend=FALSE,
    min.segment.length=0.3,
    box.padding=0.4,
    fontface="italic"
  ) +

  scale_x_reverse(
    limits=c(460, -10),
    breaks=c(400, 300, 200, 100, 50, 10, 0),
    labels=c("400","300","200","100","50","10","0")
  ) +
  scale_y_continuous(
    limits=c(0, 15000),
    breaks=seq(0, 14000, by=2000),
    labels=scales::comma,
    expand=c(0,0)
  ) +
  scale_fill_manual(values=cols, name=NULL) +
  scale_color_manual(values=cols, name=NULL) +
  scale_shape_manual(values=shapes, name=NULL) +

  labs(
    title="Neandertal effective population size through time",
    subtitle=paste0(
      "SH values calibrated (1.82\u00d7)  \u00b7  ",
      "dashed curve = exponential decay model (illustrative)  \u00b7  ",
      "\u03bc = 1.25\u00d710\u207b\u2078"
    ),
    x="Age (ka BP)",
    y=expression(paste("Ne (heterozygosity-derived proxy)"))
  ) +

  annotate("text", x=240, y=7500,
           label=expression(paste(
             N[e](t)==N[asym]+Delta*N%.%e^{-lambda*t}
           )),
           size=3.5, color="grey40", fontface="italic") +

  theme_classic(base_size=12) +
  theme(
    plot.background  = element_rect(fill="white", color=NA),
    panel.background = element_rect(fill="white", color=NA),
    plot.title    = element_text(size=12, face="bold", color="black"),
    plot.subtitle = element_text(size=9, color="grey40"),
    axis.text     = element_text(size=10, color="black"),
    legend.position = c(0.75, 0.75),
    legend.background = element_rect(fill="white",
                                      color="grey85",
                                      linewidth=0.3)
  )

ggsave("~/PopSize/results/Ne_decay_SH.pdf",
       p, width=10, height=6, device="pdf", bg="white")
ggsave("~/PopSize/results/Ne_decay_SH.png",
       p, width=10, height=6, dpi=300, bg="white")

cat("✓ Ne decay figure guardada\n")
cat(sprintf("Lambda = %.5f (ka-1)\n", lambda))
cat(sprintf("Halflife = %.0f ka\n", log(2)/lambda))
