
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SURVEY_FORM_precise_coords.csv

Infomation for external users:
When downloading data for external projects, coordinates are generally rounded to geographic minutes.
Please consider this spatial uncertainty when working with our data!
Nevertheless, some countries grant access to more precise coordinates.
These are located in a separate file in this download folder at "adds/[plot_file_name]_precise_coords.csv".
If you wish to update the delivered coordinates in the plot file (columns: latitude, longitude) with the more precise coordinates (columns: latitude_precise, longitude_precise),
then use following columns for the needed SQL join:
survey_year, code_country, code_plot, latitude, longitude

More information about the handling of our coordinates can be found under:
https://icp-forests.org/documentation/Explanatory_Items/4.html
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
data_availability_gv.csv

The file contains aggregated information about available data of this survey.


ATTRIBUTE CATALOGUE*:
- survey_year (PK**): 	year of the data recording
- code_country (PK**): 	ID of the country (data dictionary under: https://icp-forests.org/documentation/Dictionaries/d_country.html)
- partner_code: 		ID of the data submitting party (data dictionary under: https://icp-forests.org/documentation/Dictionaries/d_partner.html)
- code_plot (PK**): 	Unique/persistend plot identifier in a country
- sample_id (PK**):		Unique/persistend ID of each sampling unit on the plot
- survey_number (PK**):	Unique number per survey conducted in a sampling unit during this year

- portal_use:					"1": the data has been submitted and tested using the ICP Forests DB / "0": the data has NOT been submitted and tested using the ICP Forests DB
- darq:							"1": there is a Data Accompanying Report (DAR-Q) available for this submission *** / "0": no DAR-Q available
- free_files:					"1": any additional free files have been uploaded with the data *** / "0" no additional free files available


Additional columns indicate if information of the corresponding form is available ("1") or not available ("0").
Forms are documented under: https://icp-forests.org/documentation/Surveys/GV/index.html


* 	column wise description
** 	primary key
*** download under:https://icp-forests.org/documentation-adds/free-files/    
	documentation under: https://icp-forests.org/documentation/Introduction/Download.html
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dar_plots_submitted_SURVEYCODE.csv

This data availability report (dar) summarizes the number of plots submitted from each partner for a specific year.

ATTRIBUTE CATALOGUE*:
- survey_code:	two-digits code of the survey (e.g. "dp" = deposition)
- code_country: ID of the country (data dictionary under: https://icp-forests.org/documentation/Dictionaries/d_country.html)
- partner_code: ID of the data submitting party (data dictionary under: https://icp-forests.org/documentation/Dictionaries/d_partner.html)
- country: 		Name of the country	
- _SURVEYYEAR:	columns starting with "_" followed by a year include the number of plots submitted per partner for this year 
				(e.g. "_1995" = "5" means that 5 plots have been submitted for this survey in 1995)
				!!! entries marked with "-9999" are registered resubmissions for the future !!!
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
folder "dictionaries":

The folder named "dictionaries" includes all dictionaries of categorized variables used in this survey as CSV files.
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
attribute_catalogue_SURVEYCODE.csv

The attribute catalogue defines all columns of the main tables of the survey.

ATTRIBUTE CATALOGUE*:
- table_name:			name of the table (form)
- ordinal_position:		position of the attribute in the table (from left)
- column_name:			attribute (column) name
- data_type:			data type of the attribute (e.g. integer)
- dictionary:			dictionary used to categorize this attribute (see folder "dictionaries")
- unit_format:			unit or format used for values of this attribute
- exp_item:				link to the explanatory item further explaining the attribute
- field_desc:			short description of the attribute
- remarks:				additional remarks to the attribute
- mandatory:			"1" this attribute is mandatory / "0" this attribute is not mandatory
- key:					"1" this attribute is part of the primary key / "0" this attribute is not part of the primary key
- null_value:			NULL value used for this attribute
- ecosys_parameter:		"1" this attribute is a measured ecosystematic parameter / "0" this attribute is not a measured ecosystematic parameter (e.g. metadata)
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
known_problems_agg_survey_year_SURVEYCODE.csv

This is an aggregated overview of known problems.
The underlying script combines all tests executed during a data submission using the official data portal 
and some additional tests.

ATTRIBUTE CATALOGUE*:

- survey_code:			two-digits code of the survey (e.g. "dp" = deposition)
- form_id:				three-digits code of the form (e.g. "dem" = deposition measurements)
- survey_year:			year of the data recording
- code_country: 		ID of the country (data dictionary under: https://icp-forests.org/documentation/Dictionaries/d_country.html)
- partner_code: 		ID of the data submitting party (data dictionary under: https://icp-forests.org/documentation/Dictionaries/d_partner.html)
- attribute:			name of the tested attribute (this column just has a value if only one attribute is part of the test)
- test_class:			test category (e.g. "RANGETEST")
- val_rule_id:			unique ID of the test in the corresponding "test_class"
- msg_code:				unique ID of the message raised by the test (test_class + val_rule_id)
- error_reason:			verbal description of the problem
- number_cases:			rows of the corresponding form effected by this problem
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
known_problems_SURVEYCODE.csv

!!! This file is not part of this archive. It can be downloaded from: https://icp-forests.org/dar/ !!!

This file is the unaggregated version of the file "known_problems_agg_survey_year_SURVEYCODE.csv"
described above.
With this file the errors identified can be joined with the corresponding data row directly.

!!! Please be aware that the size of these files can be up to 2 GB !!!

ATTRIBUTE CATALOGUE*:
- survey_code:			two-digits code of the survey (e.g. "dp" = deposition)
- form_id:				three-digits code of the form (e.g. "dem" = deposition measurements)
- code_line				unique ID over the complete database (with this ID the errors can be joined to the corresponding data row)
- survey_year:			year of the data recording
- code_country: 		ID of the country (data dictionary under: https://icp-forests.org/documentation/Dictionaries/d_country.html)
- partner_code: 		ID of the data submitting party (data dictionary under: https://icp-forests.org/documentation/Dictionaries/d_partner.html)
- code_plot: 			Unique/persistend plot identifier in a country
- attribute:			name of the tested attribute (this column just has a value if only one attribute is part of the test)
- sampler				ID of the corresponding sampler if the test refers to a sampler
- test_class:			test category (e.g. "RANGETEST")
- val_rule_id:			unique ID of the test in the corresponding "test_class"
- msg_code:				unique ID of the message raised by the test (test_class + val_rule_id)
- measurement_date		date of the corresponding measurement (just available if it fits to the test)
- error_reason:			verbal description of the problem
- change_date			date on which the corresponding data row has been changed / inserted in the database

