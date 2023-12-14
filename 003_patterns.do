cls
** HEADER -----------------------------------------------------
	**  DO-FILE METADATA
	**  Project:      	HPACC
	**	Sub-Project:	Social gradients of health in SIDS
	**  Analyst:		Christina Howitt
	**	Date Created:	2023-11-16
	**  Algorithm Task: Examine the relationship between selected SDoH and outcomes (obesity and diabetes) 

    ** General algorithm set-up
    version 17
    clear all
    macro drop _all
    set more 1
    set linesize 80


** Set working directories: this is for DATASET and LOGFILE import and export
    ** DATASETS to encrypted SharePoint folder
    local datapath "C:\DataGroup - repo_data\data_p162"
     ** LOGFILES to unencrypted OneDrive folder (.gitignore set to IGNORE log files on PUSH to GitHub)
    local logpath "C:\DataGroup - repo_data\data_p162"
    ** GRAPHS to project output folder
    local outputpath "C:\Users\20004131\OneDrive - The University of the West Indies\PROJECT_p120\05_Outputs"

    ** Close any open log file and open a new log file
    capture log close
    log using "`logpath'\hpacc_sids_outcomes", replace

* ---------------------------------------------------------------------------------------------------------------------------
** STEP 1. LOAD DATASET
* ---------------------------------------------------------------------------------------------------------------------------
use "`datapath'\version01\2-working\HPACC_working", replace 

/* ---------------------------------------------------------------------------------------------------------------------------
** STEP 2. TABULATE UNWEIGHTED DATA
* ---------------------------------------------------------------------------------------------------------------------------

** Obesity 
proportion obese if sex==1 & sids==1, over(educat)
proportion obese if sex==1 & sids==0, over(educat)
proportion obese if sex==0 & sids==1, over(educat)
proportion obese if sex==0 & sids==0, over(educat) 

proportion obese if sex==1 & sids==1, over(age15)
proportion obese if sex==1 & sids==0, over(age15)
proportion obese if sex==0 & sids==1, over(age15)
proportion obese if sex==0 & sids==0, over(age15) 


** Diabetes 
proportion diab_def1 if sex==1 & sids==1, over(educat)
proportion diab_def1 if sex==1 & sids==0, over(educat)
proportion diab_def1 if sex==0 & sids==1, over(educat)
proportion diab_def1 if sex==0 & sids==0, over(educat) 

proportion diab_def1 if sex==1 & sids==1, over(age15)
proportion diab_def1 if sex==1 & sids==0, over(age15)
proportion diab_def1 if sex==0 & sids==1, over(age15)
proportion diab_def1 if sex==0 & sids==0, over(age15) 



* ---------------------------------------------------------------------------------------------------------------------------
** STEP 2. TABULATE WEIGHTED DATA
* ---------------------------------------------------------------------------------------------------------------------------
**Obesity
* define sample and adjust for non-response
generate insample = (obese < . & (age >= 15 & age < .) & pregnant != 1)

* generate survey weight variable
generate w_new = w2 if insample == 1

* generate average weight in Country and replace missing weights with mean
bysort Country: egen mean_w_new = mean(w_new) if w_new != 0						
replace w_new = mean_w_new if w_new == . & insample == 1

* weigh countries according to population size
bysort Country: egen all_obs = sum(w_new) if w_new !=. & w_new!=0
generate wpop_w_new = .
replace wpop_w_new = w_new*(Population2015/all_obs)

* define sampling design
svyset psu[pw = wpop_w_new], strata(stratum) singleunit(centered)

* estimate obesity prevalence
svy, subpop(insample): proportion obese if sids==1 & sex==1
svy, subpop(insample): proportion obese if sids==0 & sex==1
svy, subpop(insample): proportion obese if sids==1 & sex==0
svy, subpop(insample): proportion obese if sids==0 & sex==0

drop insample w_new mean_w_new all_obs wpop_w_new  


* ---------------------------------------------------------------------------------------------------------------------------
** STEP 3. TABULATE OBESITY BY SOCIODEMOGRAPHIC VARIABLES, APPLYING SURVEY WEIGHTS
* ---------------------------------------------------------------------------------------------------------------------------

* define sample and adjust for non-response
generate insample = (obese < . & (age >= 15 & age < .) & educat !=. & pregnant !=1)

* generate survey weight variable
generate w_new = w2 if insample == 1 

* generate average weight in each country and replace missing weights with mean
bysort Country: egen mean_w_new = mean(w_new) if w_new != 0 
replace w_new = mean_w_new if w_new == . & insample == 1

* weigh countries according to population size
bysort Country: egen all_obs = sum(w_new) if w_new !=. & w_new != 0
generate wpop_w_new = .
replace wpop_w_new = w_new * (Population2015/all_obs)

* define sampling design
svyset psu[pw = wpop_w_new], strata(stratum) singleunit(centered)

* tabulate obesity prevalence by age and education category
svy: tab age15 obese if insample==1 & sids==1 & sex==1, perc row ci 
svy: tab age15 obese if insample==1 & sids==0 & sex==1, perc row ci 
svy: tab age15 obese if insample==1 & sids==1 & sex==0, perc row ci 
svy: tab age15 obese if insample==1 & sids==0 & sex==0, perc row ci 

svy: tab educat obese if insample==1 & sids==1 & sex==1, perc row ci 
svy: tab educat obese if insample==1 & sids==0 & sex==1, perc row ci 
svy: tab educat obese if insample==1 & sids==1 & sex==0, perc row ci 
svy: tab educat obese if insample==1 & sids==0 & sex==0, perc row ci 


* multivariable Poisson regression
svy: glm obese i.educat age income if insample==1 & sids==1 & sex==1, fam(p) nolog eform
svy: glm obese i.educat age income if insample==1 & sids==0 & sex==1, fam(p) nolog eform
svy: glm obese i.educat age income if insample==1 & sids==1 & sex==0, fam(p) nolog eform
svy: glm obese i.educat age income if insample==1 & sids==0 & sex==0, fam(p) nolog eform


drop insample w_new mean_w_new all_obs wpop_w_new  

*/
* ---------------------------------------------------------------------------------------------------------------------------
** STEP 3. TABULATE DIABETES BY SOCIODEMOGRAPHIC VARIABLES, APPLYING SURVEY WEIGHTS
* ---------------------------------------------------------------------------------------------------------------------------

* define sample and adjust for non-response
generate insample = (diab_def1 < . & (age >= 15 & age < .) & educat !=. & pregnant !=1)

* generate survey weight variable
generate w_new = w3 if insample == 1 

* generate average weight in each country and replace missing weights with mean
bysort Country: egen mean_w_new = mean(w_new) if w_new != 0 
replace w_new = mean_w_new if w_new == . & insample == 1

* weigh countries according to population size
bysort Country: egen all_obs = sum(w_new) if w_new !=. & w_new != 0
generate wpop_w_new = .
replace wpop_w_new = w_new * (Population2015/all_obs)

* define sampling design
svyset psu[pw = wpop_w_new], strata(stratum) singleunit(centered)

* tabulate diabetes prevalence by age and education category
svy: tab age15 diab_def1 if insample==1 & sids==1 & sex==1, perc row ci 
svy: tab age15 diab_def1 if insample==1 & sids==0 & sex==1, perc row ci 
svy: tab age15 diab_def1 if insample==1 & sids==1 & sex==0, perc row ci 
svy: tab age15 diab_def1 if insample==1 & sids==0 & sex==0, perc row ci 

svy: tab educat diab_def1 if insample==1 & sids==1 & sex==1, perc row ci 
svy: tab educat diab_def1 if insample==1 & sids==0 & sex==1, perc row ci 
svy: tab educat diab_def1 if insample==1 & sids==1 & sex==0, perc row ci 
svy: tab educat diab_def1 if insample==1 & sids==0 & sex==0, perc row ci 


* multivariable Poisson regression
svy: glm diab_def1 i.educat age income if insample==1 & sids==1 & sex==1, fam(p) nolog eform
svy: glm diab_def1 i.educat age income if insample==1 & sids==0 & sex==1, fam(p) nolog eform
svy: glm diab_def1 i.educat age income if insample==1 & sids==1 & sex==0, fam(p) nolog eform
svy: glm diab_def1 i.educat age income if insample==1 & sids==0 & sex==0, fam(p) nolog eform


drop insample w_new mean_w_new all_obs wpop_w_new  

