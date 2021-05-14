# What is the association between internet search trends and COVID-19 vaccination rates? 
*An infoepidemiologic analysis for Data Science for Public Health 2021*  
*Zach Murphy, Neha Anand, John Morkos, Thomas Le* 
 
 **Find it here:** [Insert link here]
 
 ## Summary
 This is a Shiny app to visualize the relationship between Google search trends and daily vaccinations by US states from January 1st 2021 to May 11th, 2021. **Do Google search trends help predict the number of daily vaccinations?**
 
 ## Description of app 
 There are two tabs: "Heat Map" and "Graph of Trends". There are six search terms of interest: "covid", "vaccine", "vaccine near me", "mask", "social distancing", and "qanon". 
  
 ### Heat Map 
 This is a heat map of the 48 contiguous US states showing the correlation between a given search term and daily vaccinations. On the left header you can whether you are interested in vaccinations per million/vaccinations, and the google search term of interest. The correlation value ranges from -1 to 1 (blue to red), indicating there is either a negative or positive correlation between the google search term and the daily vaccinations. In other words, whether an increase in search term volume causes an increase or decrease in vaccination numbers.
<p>You can also select a time lag to ask if there is a particular time lag between google search trends affecting vaccination numbers. For example, how long does it take for a given search volume in Google to affect daily vaccination numbers? 
  
 ### Graphs of Trends 
 Here you can plot the daily vaccinations on top of the Google search trend results. On the left bar you can choose whether you're interested in daily vaccinations or daily vaccinations per million, and also the specific Google search term of interest. You can also select whether to use a smoother (using a loess smoother) and add up to 5 states for comparison. 
  
  ## Technical details 
  
  ### Correlation  
  First, time series data for both google trends and vaccination rates was fit using an Auto Regressive Integrated Moving Average (ARIMA) (https://online.stat.psu.edu/stat510/lesson/1). Then, the residuals from the two models were compared to each other using cross-correlation, resulting in a value from -1 to 1 that indicates the direction of association. This was pre-computed (not computed in Shiny) for ease of loading. 
   
 ### Google Trends normalization 
 How Google normalizes their Trends data can be found here (https://support.google.com/trends/answer/4365533?hl=en&ref_topic=6248052). Also, of interest may be a more technical description of how to de-normalize Google Trends data: https://www.jmir.org/2020/1/e13347/#ref59 

  ## Data sources 
  
 Vaccination data from: Our World in Data - https://github.com/owid/covid-19-data/tree/master/public/data/vaccinations 
 <p>Cases and deaths data from: COVID-19 Data Repository by the Center for Systems Science and Engineering (CSSE) at Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_time_series
