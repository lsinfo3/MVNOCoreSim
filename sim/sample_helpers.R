cmap.in.sample <- dt_times[span_short == "cmap_in"]$sample
cmap.in.function <- function(x = 1) sample(cmap.in.sample, x, replace = T)

cmap.out.sample <- dt_times[span_short == "cmap_out"]$sample
cmap.out.function <- function(x = 1) sample(cmap.out.sample, x, replace = T)

hlr.hit.sample <- dt_times[span_short == "hlr_hit"]$sample
hlr.hit.function <- function(x = 1) sample(hlr.hit.sample, x, replace = T)

hlr.miss.sample <- dt_times[span_short == "hlr_miss"]$sample
hlr.miss.function <- function(x = 1) sample(hlr.miss.sample, x, replace = T)

isd.sample <- dt_times[span_short == "isd"]$sample
isd.function <- function(x = 1) sum(sample(isd.sample, x, replace = T)) # Note that multiple samples will get summed here!

auc.genkeys.sample <- dt_times[span_short == "auc_genkeys" & sample >= 0]$sample
auc.genkeys.function <- function(x = 1) sample(auc.genkeys.sample, x, replace = T)

auc.upseq.sample <- dt_times[span_short == "auc_upseq"]$sample
auc.upseq.function <- function(x = 1) sample(auc.upseq.sample, x, replace = T)

#spc.sms.quantile <- quantile(dt_times[span_short == "hlr_spc_sms"]$sample, 0.90)
spc.sms.sample <- dt_times[span_short == "hlr_spc_sms"]$sample # Note the weird naming. It was decided to only involve SPC in this span
#spc.sms.sample <- rep(14000, 10)
spc.sms.function <- function(x = 1) sample(spc.sms.sample, x, replace = T)

# spc.dbquery.sample <- dt_times[span_short == "spc_dbquery"]$sample
# spc.dbquery.function <- function(x = 1) sample(spc.dbquery.sample, x, replace = T)

spc.hit.sample <- dt_times[span_short == "spc_hit"]$sample
spc.hit.function <- function(x = 1) sample(spc.hit.sample, x, replace = T)

spc.miss.sample <- dt_times[span_short == "spc_miss"]$sample
#spc.miss.sample <- rep(65000, 10)
spc.miss.function <- function(x = 1) sample(spc.miss.sample, x, replace = T)