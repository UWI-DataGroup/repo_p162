cls
** HEADER -----------------------------------------------------
	**  DO-FILE METADATA
	**  Project:      	HPACC
	**	Sub-Project:	Social gradients of health in SIDS
	**  Analyst:		Christina Howitt
	**	Date Created:	2023-08-16
	**  Algorithm Task: Bring HPACC dataset together (downloaded in two parts) and merge with other relevant datasets to prepare for analysis

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
    log using "`logpath'\hpacc_sids_prep", replace

** HEADER -----------------------------------------------------

* ---------------------------------------------------------------------------------------------------------------------------
** STEP 1. DATASET PREPARATION
** Combine parts 1 and 2 of HPACC dataset
* ---------------------------------------------------------------------------------------------------------------------------

use "`datapath'\version01\1-input\HPACC_Maindata_Pt2_2023-06-30.dta", clear
append using "`datapath'\version01\1-input\HPACC_Maindata_Pt1_2023-06-30.dta"

save "`datapath'\version01\1-input\HPACC_append.dta", replace

*keep Country year svy psu stratum rural d_id c_id c_name hh_id p_id hh_wt p_wt wstep1 wstep2 wstep3 sex	age_c age_sr age age_5yr age_10yr edyears educat educat_lcl race marital	///
work working adults_hh	total_hh income_wk	income_mth	income_yr	income_nr income_cat income_std	pcincome_std asset_index wealth_quintile ///
bg_ms hbg	hbg12 dia_med dia_medincl insulin adv_qsmokd adv_saltd adv_fvd adv_fatd adv_pad adv_bwd dia_diet hbg_th hbg_tr fast tbg	fbg	hba1c_m	hba1c_p	bg_med	///
ht	wt	bmi	bmicat	overweight obese wcirc	high_wc hcirc wh_ratio	high_whr Population2015	w1 w2 w3 stratum stratum_num psu_num pregnant

tempfile hpacc_comb
save `hpacc_comb', replace 

* ---------------------------------------------------------------------------------------------------------------------------
** Use UN country code listing, available from: https://github.com/lukes/ISO-3166-Countries-with-Regional-Codes/blob/master/all/all.csv
** To be merged with HPACC Main Data Part 2
* ---------------------------------------------------------------------------------------------------------------------------

import delimited "`datapath'\version01\1-input\country_codes.csv", clear 

rename name Country
merge 1:m Country using `hpacc_comb'

tab Country if _merge==2

** the below countries name in text did not match the csv file, so will put in manually
/*

                                Country |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                                   Iran |     30,541       32.55       32.55
                                   Laos |      2,564        2.73       35.28
                                Moldova |      4,807        5.12       40.41
                       South Africa DHS |     37,925       40.42       80.83
                              Swaziland |      3,531        3.76       84.59
                               Tanzania |      5,600        5.97       90.56
                            Timor Leste |      2,609        2.78       93.34
                                Vietnam |      3,758        4.01       97.34
                               Zanzibar |      2,492        2.66      100.00
----------------------------------------+-----------------------------------
                                  Total |     93,827      100.00

*/ 

            replace alpha2="IR" if Country=="Iran" 
            replace alpha3="IRN" if Country=="Iran"
            replace countrycode=364 if Country=="Iran"

            replace alpha2="LA" if Country=="Laos" 
            replace alpha3="LAO" if Country=="Laos"
            replace countrycode=418 if Country=="Laos"

            replace alpha2="MD" if Country=="Moldova" 
            replace alpha3="MDA" if Country=="Moldova"
            replace countrycode=498 if Country=="Moldova"

            replace alpha2="ZA" if Country=="South Africa DHS" 
            replace alpha3="ZAF" if Country=="South Africa DHS"
            replace countrycode=710 if Country=="South Africa DHS"

            replace alpha2="SZ" if Country=="Swaziland" 
            replace alpha3="SWZ" if Country=="Swaziland"
            replace countrycode=748 if Country=="Swaziland"

            replace alpha2="TZ" if Country=="Tanzania" 
            replace alpha3="TZA" if Country=="Tanzania"
            replace countrycode=834 if Country=="Tanzania"

            replace alpha2="TL" if Country=="Timor Leste" 
            replace alpha3="TLS" if Country=="Timor Leste"
            replace countrycode=626 if Country=="Timor Leste"

            replace alpha2="VN" if Country=="Vietnam" 
            replace alpha3="VNM" if Country=="Vietnam"
            replace countrycode=704 if Country=="Vietnam"

            replace alpha2="TZ" if Country=="Zanzibar" 
            replace alpha3="TZA" if Country=="Zanzibar"
            replace countrycode=834 if Country=="Zanzibar" // Note that Zanzibar is part of Tanzania


drop if _merge==1
drop _merge 

drop intermediateregioncode iso_31662 region subregion intermediateregion regioncode subregioncode

*---------------------------------------------------------------------------------------------------------------------------
* Bring in World Bank Income groups, available from: https://datahelpdesk.worldbank.org/knowledgebase/articles/906519-world-bank-country-and-lending-groups
*---------------------------------------------------------------------------------------------------------------------------

tempfile hpacc
save `hpacc', replace 

clear 

import excel "`datapath'\version01\1-input\WB_CLASS.xlsx", firstrow 

rename Code alpha3
encode alpha3, gen(num)
drop if num==.

merge 1:m alpha3 using `hpacc'

tab _merge
/*
   Matching result from |
                  merge |      Freq.     Percent        Cum.
------------------------+-----------------------------------
        Master only (1) |        184        0.01        0.01
         Using only (2) |        554        0.04        0.05
            Matched (3) |  1,522,781       99.95      100.00
------------------------+-----------------------------------
                  Total |  1,523,519      100.00

*/

tab Country if _merge==2 // The 554 participants are from Tokelau, which is a dependent territory of New Zealand, and therefore does not its own income classification'
drop if _merge==1

* We are only interested in income classification from the World Bank, so dropping superfluous variables
drop _merge F Economy Region Lendingcategory num
order alpha3, before(alpha2)
order Incomegroup, after(countrycode)
label variable alpha3 "ISO 3166-1 3-letter"
label variable alpha2 "ISO 3166-1 2-letter"
label variable countrycode "ISO 3166-1 numeric"

* Create labelled numerical group for income classification 
encode Incomegroup, gen(Income)
order Income, after(Incomegroup)
drop Incomegroup

** Save dataset for later use
save "`datapath'\version01\1-input\HPACC_SIDS.dta", replace 


