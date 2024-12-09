*  Declare input parameter;
%global curruser targetuser;

*  Write the custom HTML to _webout;

data _null_;
file _webout;
put '<!DOCTYPE html>';
put '<html>';
put '<head><title>Clone User Groups</title></head>';
put '<body>';
put "<h1>Result of clone user groups process</h1>";
put "<h4>Source user entered: %sysfunc(htmlencode(&curruser)) - Target user entered: %sysfunc(htmlencode(&targetuser))</h4>";
put '</body>';
put '</html>';
run;

/* get micro services URL */
%let BASE_URI=%sysfunc(getoption(SERVICESBASEURL));
/* Get list of users */
filename users_f temp;

proc http method='GET' CLEAR_CACHE
out=users_f 
oauth_bearer=sas_services 
url="&BASE_URI./identities/users?limit=10000";
headers "Accept"="application/json";
Run;

libname users_j JSON fileref=users_f;

data viya_users_curr (keep=id name);
  set users_j.items;
  where lowcase(id) like lowcase("%%&curruser%");*/
run;

data _null_ ;
  if 0 then set viya_users_curr nobs=n;
  call symputx('nrows',n);
  stop;
run;

%if %upcase(&nrows)>0 %then
%do;
  ods html body=_webout ;
  proc print data=viya_users_curr noobs label style(table)={just=l};
	  var id name ;
	  label id='Source ID'
	        name='Source Name';
  run;
  ods html close;
  %end;
%else
%do;
  data _null_;
    file _webout;
    put '<!DOCTYPE html>';
    put '<html>';
    put '<body>';
    put "<h4>There are no details for user: %sysfunc(htmlencode(&curruser))</h4>";
    put '</body>';
    put '</html>';
  run;
%end;

data viya_users_target (keep=id name);
  set users_j.items;
  where lowcase(id) like lowcase("%%&targetuser%");*/
run;

data _null_ ;
  if 0 then set viya_users_target nobs=n;
  call symputx('nrows',n);
  stop;
run;

%if %upcase(&nrows)>0 %then
%do;
  ods html body=_webout ;
  proc print data=viya_users_target noobs label style(table)={just=l};
    var id name ;
    label id='Target ID'
          name='Target Name';
  run;
  ods html close;
%end;
%else
%do;
  data _null_;
    file _webout;
    put '<!DOCTYPE html>';
    put '<html>';
    put '<body>';
    put "<h4>There are no details for user: %sysfunc(htmlencode(&targetuser))</h4>";
    put '</body>';
    put '</html>';
  run;
%end;

/* get list of groups for current user */
filename groups_c temp;

proc http method='GET' CLEAR_CACHE
   out=groups_c
   oauth_bearer=sas_services 
   url="&BASE_URI./identities/users/&curruser/memberships?start=0&limit=100000&showDuplicates=false&depth=1";
   headers "Accept"="application/json";
run;

libname groups_c JSON fileref=groups_c;

data work.viya_group_members_curr_user (keep=id) ;
   set groups_c.items;
run;

/* get list of groups for target user */
filename groups_t temp;

proc http method='GET' CLEAR_CACHE
   out=groups_t
   oauth_bearer=sas_services 
   url="&BASE_URI./identities/users/&targetuser/memberships?start=0&limit=100000&showDuplicates=false&depth=1";
   headers "Accept"="application/json";
run;

libname groups_t JSON fileref=groups_t;

* Select groups only on source ID, that target doesn't already have and 
  only match <a pattern>;
PROC SQL NOPRINT;
  CREATE TABLE work.groups_to_add_to_target_user AS
  SELECT     current.id
  FROM       groups_c.items current
  LEFT JOIN  groups_t.items target
  ON         current.id = target.id
  WHERE      target.id is NULL AND 
             current.id <some site specific pattern>
  ORDER BY   current.id ;
QUIT ;

* Select groups only on source ID, that target needs removing and 
  only beging with OTRCIS_;
PROC SQL NOPRINT;
  CREATE TABLE work.groups_to_del_from_target_user AS
  SELECT     target.id
  FROM       groups_c.items current
  RIGHT JOIN groups_t.items target
  ON         current.id = target.id
  WHERE      current.id is NULL AND 
             target.id <some site specific pattern>
  ORDER BY   target.id ;
QUIT ;

filename groups_t clear;
libname groups_t clear;
filename groups_c clear;
libname groups_c clear;

%macro add_user_to_groups(group);
proc http method="PUT" CLEAR_CACHE 
      oauth_bearer=sas_services 
      url="&BASE_URI./identities/groups/&group./userMembers/&targetuser.";
      headers "Accept"="application/json";
quit;
%mend;

/* loop through each record to get groups then add to user to it */
data _null_;
  set work.groups_to_add_to_target_user ;
  call execute ('%nrstr(%add_user_to_groups('||strip(id)||'));');
run;

data _null_ ;
  if 0 then set groups_to_add_to_target_user nobs=n;
  call symputx('nrows',n);
  stop;
run;

data _null_;
    file _webout;
    put '<!DOCTYPE html>';
    put '<html>';
    put '<body>';
    put "<h4>There were: %sysfunc(htmlencode(&nrows)) groups added to userid: %sysfunc(htmlencode(&targetuser))</h4>";
    put '</body>';
    put '</html>';
  run;
  
%if %upcase(&nrows)>0 %then
%do;
  ods html body=_webout ;
  * Display simple report to show which groups were copied;
  proc print data=groups_to_add_to_target_user noobs label style(table)={just=l};
	var id ;
	label id='Group ID Copied';
  run;
  ods html close;
%end;

* Delete groups;
%macro del_user_from_groups(group);
proc http method="DELETE" CLEAR_CACHE 
      oauth_bearer=sas_services 
      url="&BASE_URI./identities/groups/&group./userMembers/&targetuser.";
      headers "Accept"="application/json";
quit;
%mend;

/* loop through each record to get groups then add to user to it */
data _null_;
  set work.groups_to_del_from_target_user ;
  call execute ('%nrstr(%del_user_from_groups('||strip(id)||'));');
run;

data _null_ ;
  if 0 then set groups_to_del_from_target_user nobs=n;
  call symputx('nrows',n);
  stop;
run;

data _null_;
    file _webout;
    put '<!DOCTYPE html>';
    put '<html>';
    put '<body>';
    put "<h4>There were: %sysfunc(htmlencode(&nrows)) groups deleted from userid: %sysfunc(htmlencode(&targetuser))</h4>";
    put '</body>';
    put '</html>';
  run;
  
%if %upcase(&nrows)>0 %then
%do;
  ods html body=_webout ;
  * Display simple report to show which groups were deleted;
  proc print data=groups_to_del_from_target_user noobs label style(table)={just=l};
	var id ;
	label id='Group ID Deleted';
  run;
  ods html close;
%end;
