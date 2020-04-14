Short Code Lookup
==============

## Summary
Numourous guides and videos link to the short code (1234) which are currently unavailable whilst the site is offline. This proposal bridges the gap to allow users to continue to access these builds whilst the main site's host is complete

## Details
Links such as https://s.orbis.zone/1w-a currently display a 522 error which could cause frustration to the end user looking for specific builds. This proposal bridges this gap by taking the short code, convert to the longer code (outfit/python?code=A0pktkFflidkssf52m3M-3R3R2x04etc) and redirecting to a working clone of the website, for example coriolis.sourcebin.org. This would allow the user to view the build until such time that the main site is back online. 

## Requirements
* CSV dump of public short codes to long code (possibly including the ship if neccessary)
* Serverless Function
* Permission to redirect to clone site, otherwise hosting of the site with the function

## Owners
* Implementation: Myself (Senior SRE)
* Data: Coriolis devs (data controllers)
* Clone Site: Chapter4 (as this will increase web traffic to destination)

## Implementation
* A one off but repeatable import of CSV data to Azure Table Storage ($0.06/month), indexed on short code
* A simple Go function to grab the short code from storage, check if it exists, take the long code and redirect the browser to the clone site with the new URL
* If no path is detected then a very basic front page explaining the site, entry for a short code and submit button (functional, doesn't have to look pritty)
* If code is not found then return error page, stating this is a temporary solution until the main site is online and links on how to track this

## Additional Information
URL will be generated by Azure/AWS either by the function or through an LB. Domains/subdomains can be linked through CNAME to the domain. 

## Workflow
**User Browser (GET)**
Either user enters code through basic web page, or through URL

**Function (Go) Called**
Serverless function auto-load balancing by Azure LB

**Get Short Code and lookup in Storage Table**
Get short code from path, ensure it's valid and lookup. Error if it doesn't exist. 

**Render long URL and Redirect Browser to Clone Site**
Browser will receive HTTP Code 307, temporary redirect.

## Estimated Costs/Limits
| Service       | Free/Cost     |
| ------------- |:-------------:|
| LB with IP    | Free          |
| Function      | 1m calls / month free, PAYG after |
| Storage       | $0.06/GB/month   |
| Ingress/Egress| Minimal      |
