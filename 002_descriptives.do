cls
** HEADER -----------------------------------------------------
	**  DO-FILE METADATA
	**  Project:      	HPACC
	**	Sub-Project:	Social gradients of health in SIDS
	**  Analyst:		Christina Howitt
	**	Date Created:	2023-09-06
	**  Algorithm Task: Dataset descriptives, plus a first look at prevalence of outcomes and SDoH predictors

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
    log using "`logpath'\hpacc_sids_desc", replace


* ---------------------------------------------------------------------------------------------------------------------------
** STEP 1. Load Data 
* ---------------------------------------------------------------------------------------------------------------------------
use "`datapath'\version01\1-input\HPACC_SIDS.dta", clear

* ---------------------------------------------------------------------------------------------------------------------------
** STEP 2. Describe basic dataset characteristics
* ---------------------------------------------------------------------------------------------------------------------------

** DEFINE SIDS
gen sids = 0
replace sids = 1 if countrycode==84	| countrycode==132 | countrycode==242 | countrycode==308 | countrycode==328 | countrycode==332 | countrycode==584 | countrycode==520 | countrycode==585 | ///
countrycode==882 | countrycode==690 | countrycode==90 | countrycode==626 | countrycode==776 | countrycode==798 | countrycode==548	

order sids, after(Income)
label define sid 0 "non-sid" 1 "sid"
label values sid sid 
label variable sid "Small Island Developing State"
tab sids, miss 
tab Country sids 


** DESCRIBE INCOME 
gen income = .
replace income=1 if Income==2
replace income=2 if Income==3
replace income=3 if Income==4
replace income=4 if Income==1

label define income 1 "Low income" 2 "Lower middle income" 3 "Upper middle income" 4 "High income"
label values income income
label variable income "Country income group"
order income, before(sids)
drop Income 

preserve
    gen num = 1
    collapse (mean) num, by(Country sids income)
    tab income sids
    list Country income sids, clean
restore 

tab income sids 

* ---------------------------------------------------------------------------------------------------------------------------
** STEP 3. Describe sociodemographic characteristics
* ---------------------------------------------------------------------------------------------------------------------------

numlabel, add mask("#")

** Sex
codebook sex
replace sex=. if sex>1
label define sex 0 "Male" 1 "Female"
label values sex sex 
tab sex sids, nofreq col miss 

** Age NEED TO COME BACK TO THIS, THERE ARE 42,932 PARTICIPANTS WITH AGE < 15 YRS
drop age_sr // this is not the correct variable to be used in analysis
codebook age 
codebook age if sids==0
codebook age if sids==1
tabstat age, by(sids) stat(med p25 p75)

drop if age <15
drop if age >100 & age<.


* divide age into groups
gen age15 = .
replace age15=1 if age >=15 & age <=30
replace age15=2 if age >30 & age <=45
replace age15=3 if age >45 & age <=60
replace age15=4 if age >60 & age <=75
replace age15=5 if age >75 & age <.
label define age15 1 "15-30" 2 ">30-45" 3 ">45-60" 4 ">60-75" 5 "75+"
label values age15 age15
tab age15 sids, col miss

** Education (years completed)
codebook edyears 
replace edyears=. if edyears==555555555 | edyears==666666666 | edyears==777777777  | edyears==888888888 | edyears==999999999
codebook edyears if sids==0
codebook edyears if sids==1
tabstat edyears, by(sids) stat(med p25 p75)  // this variable doesn't make sense (values up to 95 years, some are >age, don't correspond to categorical education variable)
drop edyears

** Education (categorical, standardized)
tab educat, miss
tab educat sids, col miss 
replace educat=. if educat>4
tab educat sids, nofreq col miss 

** Marital status
tab marital sids, col miss 
replace marital=. if marital>6
tab marital sids, nofreq col miss 

** Employment status
tab work sids, nofreq col miss
replace work=. if work>9 

** Income
codebook income_wk
sort income_wk
replace income_wk=. if income_wk>=333333333 
sort income_mth 
replace income_mth=. if income_mth>=333333333
sort income_yr
replace income_yr=. if income_yr>=333333333
gen income_check=1
replace income_check=0 if income_wk==. & income_mth==. & income_yr==.
label define income_check 0 "Missing" 1 "Complete"
label values income_check income_check


* ---------------------------------------------------------------------------------------------------------------------------
** STEP 4. Describe outcome measures
* ---------------------------------------------------------------------------------------------------------------------------
** Obesity
tab bmicat, miss
tab bmicat sids, nofreq col miss

** Diabetes
* ever told diabetes
tab hbg, miss
replace hbg=. if hbg>1
tab hbg sids, nofreq col miss

* High blood sugar or diabetes past 12 months
tab hbg12, miss
replace hbg12=. if hbg12>1 
tab hbg12 sids, nofreq col miss 

* Medication for diabetes, past 2 weeks
tab dia_med, miss
replace dia_med=. if dia_med>1
tab dia_med sids, nofreq miss col

* Medication for diabetes today
tab bg_med, miss
replace bg_med=. if bg_med>1
tab bg_med sids, nofreq col miss 

* Current insulin use
tab insulin, miss
replace insulin=. if insulin>1
tab insulin sids, nofreq col miss

* Fasted at the time the sample taken
tab fast, miss
replace fast=. if fast>1
tab fast sids, nofreq col miss 

** Fasting blood glucose
codebook fbg 
replace fbg=. if fbg>100
codebook fbg if sids==1
sort fbg
replace fbg=. if fbg>100
tabstat fbg if sids==1, by("Country") stat(med p25 p75) format(%9.1f) // SIDS with missing FBG are: Grenada, Haiti, Tonga
tabstat fbg if sids==0, by("Country") stat(med p25 p75) format(%9.1f) // Non-SIDS with missing FBG are: Albania, Brazil, Egypt, Gambia, India, Indonesia, Kazakstan, Peru, Russian Federaton, Sierra Leone, South Africa, South Africa DHS, Ukraine

** IS HbA1c available for countries with no FBG?
** first look at whether there's different missing data for HbA1c in percent vs mmol/l
codebook hba1c_m
codebook hba1c_p
count if hba1c_p==. & hba1c_m!=. // can use hba1c_p as they are converted values with same missing
replace hba1c_p=. if hba1c_p>100
/**SIDS
codebook hba1c_p if Country=="Grenada"
codebook hba1c_p if Country=="Haiti" // Haiti has HbA1c
codebook hba1c_p if Country=="Tonga"
*Non-SIDS: Albania, Brazil, Egypt, Gambia, India, Indonesia, Kazakstan, Peru, Russian Federaton, Sierra Leone, South Africa, South Africa DHS, Ukraine
codebook hba1c_p if Country=="Albania" 
codebook hba1c_p if Country=="Brazil" // has some (8237 out of 60,202)
codebook hba1c_p if Country=="Egypt" 
codebook hba1c_p if Country=="Gambia"
codebook hba1c_p if Country=="India" 
codebook hba1c_p if Country=="Indonesia" // has some (7272 out of 26,138)
codebook hba1c_p if Country=="Kazakhstan" 
codebook hba1c_p if Country=="Peru"
codebook hba1c_p if Country=="Russian Federation" 
codebook hba1c_p if Country=="Sierra Leone"
codebook hba1c_p if Country=="South Africa" // has some (4615 out of 17,447)
codebook hba1c_p if Country=="South Africa DHS" // has some (6923 out of 31,002)
codebook hba1c_p if Country=="Ukraine" 
*/
/** Definition of diabetes based on HPACC diabetes prevalence paper (https://diabetesjournals.org/care/article/43/4/767/35785/Diabetes-Prevalence-and-Its-Relationship-With)
Presence of diabetes was determined based on the current WHO diagnostic thresholds as any of the following: a fasting plasma glucose ≥7.0 mmol/L (126 mg/dL), a random 
plasma glucose ≥11.1 mmol/L (200 mg/dL), or, in the case of Fiji, Indonesia, and South Africa (Note: these countries have HbA1c measurements but no fasting glucose. This has changed 
in our updated dataset), an HbA1c measurement of ≥6.5% (25). Undiagnosed diabetes was defined by meeting the above biochemical criteria in participants who self-reported no prior diabetes 
diagnosis. Individuals reporting use of drugs for blood glucose control were also classified as having diabetes, irrespective of the biomarker values. Respondents who self-reported a diagnosis 
of diabetes but were not on diabetes medications and did not meet the biomarker diagnostic criteria were not classified as having diabetes.
*/

** Raised glucose (fasting and non-fasting)
gen diab_fg = 0
replace diab_fg = 1 if fbg >=7 & fbg <. & fast==1 
replace diab_fg = 1 if fbg >=11 & fbg <. & fast==0
replace diab_fg =. if fbg==. 
** Raised HbA1c
gen diab_hb = 0
replace diab_hb = 1 if hba1c_p >=6.5 & hba1c_p <.
replace diab_hb = . if hba1c_p==.
** Combined biochemistry
gen diab_bchem = 0
replace diab_bchem = 1 if diab_fg==1
replace diab_bchem = 1 if diab_hb==1 & diab_fg==.
replace diab_bchem =. if diab_fg==. & diab_hb==.
** Known diabetes
gen diab_known = 0 
replace diab_known = 1 if hbg==1 | hbg12==1 // Ever told high blood sugar or diabetes; told in past 12 months
replace diab_known = . if hbg==. & hbg12==. 
tab diab_known, miss 
** Medication or insulin use
gen med_diab = 0
replace med_diab = 1 if dia_med==1 | insulin==1 | bg_med==1 // medication in past two weeks, current insuling use, blood glucose medication today
replace med_diab =. if dia_med==. & insulin==. & bg_med==.
tab med_diab, miss 

** create definition based on previous diagnosis, medication use, and biochemistry
gen diab_def1 = 0
replace diab_def1 = 1 if diab_known==1 | med_diab==1 | diab_bchem==1 
** Exclude from denominator people who are missing biochemistry, diagnosed, and medication
replace diab_def1 =. if diab_known==. & med_diab==. & diab_bchem==. 
** Those who self-reported a diagnosis of diabetes but were not on diabetes medications and did not meet the biomarker diagnostic criteria should not be classified as having diabetes
replace diab_def1 = 0 if diab_known==1 & med_diab==0 & diab_bchem==0



label define diab_def1 0 "no diabetes" 1 "diabetes"
label values diab_def1 diab_def1 
tab diab_def1, miss
tab diab_def1 sids, miss col nofreq 
tab diab_def1 sids, col nofreq 


*****************************************************************************************************************
* SAVE DATASET FOR FURTHER WORK
*****************************************************************************************************************
save "`datapath'\version01\2-working\HPACC_working", replace 






