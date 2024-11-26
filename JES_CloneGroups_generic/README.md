Hi everyone

This JES solution was created to answer a specific customer query. They wanted to be able to replicate the groups an existing user had onto a new user. With Viya, 
this is not possible - you have to edit each group and add the user to it. In some case, a new user might need to be added to 80+ groups causing delays and 
frustration. This gives the user the option to enter the existing user's email address, the new user's email address and then just hit submit to run the cloning
process.

You'll see in CloneGroups_generic.sas the mention of <some site specific pattern>. I specified only the groups I wanted the user running job to be able to clone. in the case of my customer the logic was "LIKE 'OTRCIS_%" as the user only had rights within EnvMgr to administer groups with this specific text. You might want to apply your own logic here. Be careful though...you don't want users copying admin groups to themselves!!!

This was my first foray into JES so I fully expect plenty of you to have suggestions for improvements - that's great. Send them in!

David Foot
SAS Application Management, SAS UK&I

david.foot@sas.com
