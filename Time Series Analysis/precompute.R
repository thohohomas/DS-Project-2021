########################################
# This script precomputes cross correlation coefficients based on SARIMA model 
# residuals with lags up to -14
########################################

# Imports
library(dplyr)
library(forecast)
library(tidyverse)

# Get Google Trends data
dat = data.frame(keyword=character(),
                 date=numeric(),
                 geo=character(),
                 hits=character())

for (f in c('GT/covid data.csv','GT/mask data.csv','GT/qanon data.csv','GT/social distancing data.csv','GT/vaccine data.csv','GT/vaccine near me data.csv')){
  newdat = read_csv(f)
  dat = rbind(dat,newdat)
}
rm(newdat, f)

dat = subset(dat, select=-c(X1))
dat$hits = as.numeric(dat$hits)

dat = dat %>% pivot_wider(names_from = keyword, values_from = hits, values_fill = 0)
dat = rename(dat, Date = date, State = geo)
write_csv(dat, 'search_data.csv')

# Get outcome data
start_date = '2021-01-01'

vaccines = read_csv("https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/vaccinations/us_state_vaccinations.csv")
vaccines = vaccines %>% rename(Date = date, Province_State = location)
vaccines = vaccines %>% filter(Date >= start_date)
vaccines = data.frame(lapply(vaccines, function(x) {gsub("New York State", "New York", x)}))

cases = read_csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv")
cases = cases %>% pivot_longer(names_to="Date", values_to="Cases", cols=colnames(cases[12:length(cases)]))
cases = cases %>% mutate(Date = as.Date(cases$Date, format ="%m/%d/%y"))
cases = cases %>% filter(Date >= start_date)
cases = cases[,c('Date', 'Province_State', 'Cases')] %>% group_by(Date,Province_State) %>% summarise(cases = sum(Cases))

deaths = read_csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv")
deaths = deaths %>% pivot_longer(names_to="Date", values_to="Deaths", cols=colnames(deaths[13:length(deaths)]))
deaths = deaths %>% mutate(Date = as.Date(deaths$Date, format ="%m/%d/%y"))
deaths = deaths %>% filter(Date >= start_date)
deaths = deaths[,c('Date', 'Province_State', 'Deaths')] %>% group_by(Date,Province_State) %>% summarise(deaths = sum(Deaths))

dat = merge(cases,deaths,by=c('Date','Province_State'), all = TRUE)
dat = merge(dat,vaccines,by=c('Date','Province_State'), all = TRUE)
dat = rename(dat, State = Province_State)

dat = dat %>% select(Date, State, everything())
write_csv(dat, 'outcomes.csv')

# Read inputs
states = state.name
search_data = read_csv('search_data.csv')
covid = read_csv('outcomes.csv')

# Merge into one data frame
timeseries = merge(search_data, covid, by=c('Date','State'))

# Results containers
state = c()
term = c()
outcome = c()
croscor = c()
lagd = c()

# For each state
for (s in states){
  state_dat = timeseries %>% filter(State == s)
  # For each pred
  for (p in colnames(search_data)[-1:-2]){
    # For each outcome
    for (o in c('daily_vaccinations', 'daily_vaccinations_per_million')){
      
      # Get ARIMA models
      xaa = auto.arima(ts(state_dat[,p]))
      yaa = auto.arima(ts(state_dat[,o]))
      
      # Get ccf
      croscor_this = ccf(xaa$residuals, yaa$residuals, lag = 14, na.action = na.contiguous, pl = FALSE)
      
      # For each lag
      for (l in seq(-14,0)){
        # Get ccf at lag
        cvalue = croscor_this$acf[match(l,croscor_this$lag)]

        # Add to results
        state = c(state, s)
        term = c(term, p)
        outcome = c(outcome, o)
        croscor = c(croscor, cvalue)
        lagd = c(lagd,l)
      }
    }
  }
  print(paste(s,'done'))
}

# Save model results
models = data.frame(state,
                    term,
                    outcome,
                    croscor,
                    lagd)
write.csv(models, 'models.csv')
write.csv(timeseries, 'timeseries.csv')
