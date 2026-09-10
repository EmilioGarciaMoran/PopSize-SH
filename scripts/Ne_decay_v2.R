library(ggplot2)
library(ggrepel)

# Puntos reales calibrados
data_points <- data.frame(
  age_ka = c(430,430,430,430, 120, 80, 54, 44, 50),
  Ne     = c(13280,13016,6487,10174, 5000,2500,3000,3000,1500),
  label  = c("molar_L35","femurXIII","scapula","femur_fragment",
             "D5 (Altai)","Chagyrskaya 8","Vindija 33.19",
             "Goyet GN1","Denisova D17"),
  group  = c("SH","SH","SH","SH",
             "Late Neandertal","Late Neandertal",
             "Late Neandertal","Late Neandertal","Denisovan")
)

# Curva exponencial ilustrativa
lambda <- -log((5000-3000)/(13000-3000)) / (430-120)
t_seq <- seq(0, 450, by=1)
Ne_curve <- 3000 + (13000-3000) * exp(-lambda * (430 - t_seq))
Ne_curve[t_seq > 430] <- NA
curve_df <- data.frame(age_ka=t_seq, Ne=Ne_curve)

# Estadios isotópicos marinos (MIS) — Europa/Eurasia
# Glaciales (fríos) en gris, Interglaciales (cálidos) en blanco
mis <- data.frame(
  start = c(450, 424, 374, 337, 300, 243, 191, 130, 71,  57,  29,  14,   0),
  end   = c(424, 374, 337, 300, 243, 191, 130,  71, 57,  29,  14,   0, -10),
  stage = c("MIS12","MIS11","MIS10","MIS9","MIS8","MIS7","MIS6",
            "MIS5","MIS4","MIS3","MIS2","MIS1",""),
  type  = c("glacial","interglacial","glacial","interglacial",
            "glacial","interglacial","glacial","interglacial",
            "glacial","interglacial","glacial","interglacial","")
)
mis$y_min <- 14800
mis$y_max <- 15800
mis$fill  <- ifelse(mis$type=="glacial","#C8D8E8","#FFF5E0")
mis$label_x <- (mis$start + mis$end) / 2

cols   <- c("SH"="#185FA5","Late Neandertal"="#A32D2D","Denisovan"="#854F0B")
shapes <- c("SH"=21,"Late Neandertal"=22,"Denisovan"=23)

p <- ggplot() +

  # MIS barra superior
  geom_rect(data=mis[mis$stage!="",],
            aes(xmin=start, xmax=end, ymin=y_min, ymax=y_max, fill=fill),
            color="grey60", linewidth=0.2, show.legend=FALSE) +
  scale_fill_identity() +
  geom_text(data=mis[mis$stage!="" & (mis$start-mis$end)>20,],
            aes(x=label_x, y=(y_min+y_max)/2, label=stage),
            size=2.5, color="grey20", fontface="bold") +

  # Etiqueta barra MIS
  annotate("text", x=455, y=15300,
           label="MIS", size=3, color="grey30",
           fontface="bold", hjust=0) +

  # Línea divisoria MIS / plot
  geom_hline(yintercept=14800, color="grey60", linewidth=0.3) +

  # Banda SH
  annotate("rect", xmin=415, xmax=445,
           ymin=0, ymax=14500,
           fill="#E6F1FB", alpha=0.4) +

  # Curva exponencial
  geom_line(data=curve_df,
            aes(x=age_ka, y=Ne),
            color="grey50", linewidth=0.8, linetype="dashed") +

  # Asíntota
  geom_hline(yintercept=3000, color="#A32D2D",
             linewidth=0.5, linetype="dotted") +
  annotate("text", x=8, y=3300,
           label="Ne minimum (~3,000)",
           color="#A32D2D", size=2.8,
           hjust=0, fontface="italic") +

  # Puntos
  geom_point(data=data_points,
             aes(x=age_ka, y=Ne,
                 fill=group, color=group, shape=group),
             size=4, stroke=0.6) +

  # Labels
  geom_text_repel(data=data_points,
                  aes(x=age_ka, y=Ne, label=label, color=group),
                  size=3, show.legend=FALSE,
                  min.segment.length=0.3,
                  box.padding=0.5,
                  fontface="italic",
                  ylim=c(0,14500)) +

  # Anotaciones climáticas clave
  annotate("text", x=400, y=500,
           label="MIS 12\n(glacial severo)", size=2.5,
           color="#5B7FA6", fontface="italic", hjust=0.5) +
  annotate("text", x=340, y=500,
           label="MIS 11\n(interglacial largo)", size=2.5,
           color="#8B6914", fontface="italic", hjust=0.5) +

  scale_x_reverse(
    limits=c(460, -10),
    breaks=c(450,400,350,300,250,200,150,100,50,0),
    labels=c("450","400","350","300","250","200","150","100","50","0"),
    expand=c(0,0)
  ) +
  scale_y_continuous(
    limits=c(0, 15800),
    breaks=seq(0,14000,by=2000),
    labels=scales::comma,
    expand=c(0,0)
  ) +
  scale_color_manual(values=cols, name=NULL) +
  scale_shape_manual(values=shapes, name=NULL) +
  guides(fill="none",
         color=guide_legend(override.aes=list(shape=c(21,22,23),
                                               fill=cols))) +

  labs(
    title = "Neandertal effective population size through time",
    subtitle = paste0(
      "SH values calibrated (\u00f71.82)  \u00b7  ",
      "dashed = exponential decay model (illustrative)  \u00b7  ",
      "\u03bc = 1.25\u00d710\u207b\u2078  \u00b7  ",
      "MIS = Marine Isotope Stages (glacial/interglacial)"
    ),
    x = "Age (ka BP)",
    y = expression(paste(N[e]," (heterozygosity-derived proxy)"))
  ) +

  theme_classic(base_size=12) +
  theme(
    plot.background  = element_rect(fill="white", color=NA),
    panel.background = element_rect(fill="white", color=NA),
    plot.title    = element_text(size=12, face="bold", color="black"),
    plot.subtitle = element_text(size=8.5, color="grey40"),
    axis.text     = element_text(size=10, color="black"),
    axis.title    = element_text(size=11, color="black"),
    legend.position = c(0.78, 0.78),
    legend.background = element_rect(fill="white",
                                      color="grey85",
                                      linewidth=0.3),
    legend.text = element_text(size=9),
    plot.margin = margin(5,15,5,5)
  )

ggsave("~/PopSize/results/Ne_decay_MIS_v2.pdf",
       p, width=11, height=6.5, device="pdf", bg="white")
ggsave("~/PopSize/results/Ne_decay_MIS_v2.png",
       p, width=11, height=6.5, dpi=300, bg="white")

cat("✓ Ne decay + MIS guardada\n")
