Short Code Lookup
==============

## Summary
Numourous guides and videos link to the short code on orbis.zone (like /1234) which are currently unavailable whilst the site is offline. This proposal bridges the gap to allow users to continue to access these builds whilst the main site is moved and brought online on the new host. There is currently no way to look up this code to the build. 

## Details
Links such as https://s.orbis.zone/1w-a currently display a 522 error which could cause frustration to the end user looking for specific builds. This proposal bridges this gap by taking the short code, convert to the longer code (outfit/python?code=A0pktkFflidkssf52m3M-3R3R2x04etc) and redirecting to a working clone of the website, for example coriolis.sourcebin.org. This would allow the user to view the build until such time that the main site is back online. 

## Requirements
* CSV dump of public short codes to long code (possibly including the ship if neccessary) - **Coriolis devs** 
* Serverless Function - **BourneID**
* Permission to redirect to clone site, otherwise hosting of another clone site will be required - **Chapter4**

## Implementation
* A one off but repeatable import of CSV data to Azure Table Storage ($0.06/month), indexed on short code
* A functionless solution in AWS using API Gateway
* If no path is detected then a very basic front page explaining the site, entry for a short code and submit button (functional, doesn't have to look pritty)
* If code is not found then return error page, stating this is a temporary solution until the main site is online and links on how to track this


## Workflow
**User Browser (GET)**
Either user enters code through basic web page, or through URL

**Functionless service**
Functionless auto-load balancing solution by AWS APi Gateway

**Get Short Code and lookup in Storage Table**
Get short code from path, ensure it's valid and lookup. Error if it doesn't exist. 

**Render long URL and Redirect Browser to Clone Site**
Browser will receive HTTP Code 307, temporary redirect.

## Estimated Costs/Limits (Covered by BourneID)
| Service       | Free/Cost     |
| ------------- |:-------------:|
| LB with IP    | Free          |
| Function      | 1m calls / month free, PAYG after |
| Storage       | $0.06/GB/month   |
| Ingress/Egress| Minimal      |
