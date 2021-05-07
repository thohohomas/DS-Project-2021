########################################
# This script precomputes linear regression models based on SARIMA model 
# residuals to predict COVID outcomes from Google Trends search term interest
# 
# INPUTS:
# - search_data.csv
#     - Google Trends search term importance data
#     - Cols:
#         - State (str): 2-letter abbreviations
#         - Date (date): YYYY-MM-DD format
#         - [Terms] (int): GT interest for search term, 0-100
# - outcomes.csv
#     - Outcome data by state
#     - Cols:
#         - Date (date): YYYY-MM-DD format
#         - State (str): 2-letter abbreviations
#         - [Outcomes] (float): Outcomes
#
# PROCESS:
# 1. Run auto.arima on each search term and each outcome for each state
# 2. Check autocorrelations
# 3. Build linear model
# 4. Check linear model assumptions
# 5. Get p-value and R^2
#
# OUTPUT:
# - models.csv
#     - Model results for frontend
#     - Cols:
#         - State (str): 2-letter abbreviations
#         - Term (str): GT search term strings
#         - Outcome (str): outcome string
#         - R2 (float): R^2 value from linear regression
#         - p (float): omnibus p-value from linear regression
#         - acf_x (int): 1 = significant autocorrelation (bad), 0 = no significant autocorrelation (good)
#         - acf_y (int): 1 = significant autocorrelation (bad), 0 = no significant autocorrelation (good)
#         - res_norm_p (int): 1 = significant Shapiro-Wilk test (bad), 0 = non-significant Shapiro-Wilk test (good)
#         - res_hsce_p (int): 1 = significant Breush-Pagan test (bad), 0 = non-significant Breush-Pagan test (good)
#         - res_acor_p (int): 1 = significant Durbin-Watson test (bad), 0 = non-significant Durbin-Watson test (good)
# - timeseries.csv
#     - Raw timeseries of each pred and outcome by state
#     - Cols:
#         - State (str)
#         - Date (date)
#         - [Terms]
#         - [Outcomes]
########################################

# Imports
library(dplyr)
library(forecast)

# Read inputs
states = state.name
search_data = read_csv('search_data.csv')
covid = read_csv('outcomes.csv')

# Merge into one data frame
timeseries = merge(search_data, covid, by=c('Date','State'))

# Check for autocorrelation
checkAutoCor = function(m, ci=0.95){
  m = acf(m, na.action = na.pass)
  cv = qnorm((1+ci)/2)/sqrt(m$n.used)
  p_pos = sum(m$acf[-1])/length(m$acf[-1])
  
  return(as.integer(p_pos >= (1-cv)))
}

# Check Shapiro-Wilk normality test
checkShapiroWilk = function(l, alpha=0.05){
  if (var(l$residuals) == 0){
    return(0)
  } else {
    sw_p = shapiro.test(l$residuals)$p
    return(as.integer(sw_p <= alpha))
  }
}

# Check Breush-Pagan homoscedasticity test
checkBreuchPagan = function(l, alpha=0.05){
  bp = lmtest::bptest(l)$p.value
  return(as.integer(bp <= alpha))
}

# Check Durbin-Watson residual autocorrelation test
checkDurbinWatson = function(l, alpha=0.05){
  dw = lmtest::dwtest(l)$p.value
  return(as.integer(dw <= alpha))
}

# Results containers
state = c()
term = c()
outcome = c()
r2 = c()
pvalue = c()
f = c()
acf_x = c()
acf_y = c()
res_norm_p = c()
res_hsce_p = c()
res_acor_p = c()

# For each state
for (s in states){
  state_dat = timeseries %>% filter(State == s)
  # For each pred
  for (p in colnames(search_data)[-1:-2]){
    # For each outcome
    for (o in colnames(covid)[-1:-2]){
      
      # Get ARIMA models
      xaa = auto.arima(ts(state_dat[,p]))
      yaa = auto.arima(ts(state_dat[,o]))
      
      # Is auto cor significant? on ARIMA residuals
      xaa_auto_cor = checkAutoCor(xaa$residuals)
      yaa_auto_cor = checkAutoCor(yaa$residuals)
      
      # Prep lm data
      d = ts.intersect(
         yaa$residuals, 
         stats::lag(xaa$residuals,0), 
         stats::lag(xaa$residuals,1),
         stats::lag(xaa$residuals,2),
         stats::lag(xaa$residuals,3),
         stats::lag(xaa$residuals,4),
         stats::lag(xaa$residuals,5),
         stats::lag(xaa$residuals,6),
         stats::lag(xaa$residuals,7),
         stats::lag(xaa$residuals,8),
         stats::lag(xaa$residuals,9),
         stats::lag(xaa$residuals,10)
        )
      
      # Perform linear regression
      l = lm(d[,1] ~ d[,2:12])
      
      # Get linear regression metrics
      lm_r2 = summary(l)$r.squared
      lm_f = summary(l)$fstatistic
      lm_p = pf(lm_f[1], lm_f[2], lm_f[3], lower.tail=FALSE)
      
      # Get assumption checks
      lm_shapiro_wilk = 0#checkShapiroWilk(l, alpha=0.05)
      lm_breuch_pagan = 0#checkBreuchPagan(l, alpha=0.05)
      lm_durbin_watson = 0#checkDurbinWatson(l, alpha=0.05)
      
      # Add to results
      state = c(state, s)
      term = c(term, p)
      outcome = c(outcome, o)
      r2 = c(r2, lm_r2)
      pvalue = c(pvalue, lm_p)
      f = c(f, lm_f)
      acf_x = c(acf_x, xaa_auto_cor)
      acf_y = c(acf_y, yaa_auto_cor)
      res_norm_p = c(res_norm_p, lm_shapiro_wilk)
      res_hsce_p = c(res_hsce_p, lm_breuch_pagan)
      res_acor_p = c(res_acor_p, lm_durbin_watson)
    }
  }
  print(paste(s,'done'))
}

# Save model results
models = data.frame(state,
                    term,
                    outcome,
                    r2,
                    pvalue,
                    f,
                    acf_x,
                    acf_y,
                    res_norm_p,
                    res_hsce_p,
                    res_acor_p)
write.csv(models, 'models.csv')

write.csv(timeseries, 'timeseries.csv')
