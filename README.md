# Lean Coffee HackMD Generator

Generates a HackMD document for future lean coffees

The HackMD document includes a few things that are a bit fiddly to generate. 

Specifically it includes a link to "agical" which allows people to download a `.ics` file representing the calendar event for the lean coffee. 

The calendar event includes a link to the HackMD, and so it has to do a "double pass":

1. generate the HackMD with incomplete content, save it and store the link
2. update the HackMD content and include the generated agical link including the link to the HackMD itself

Various things are passed to the script as secrets via github actions:

| secret | purpose |
|--------|---------|
| HACKMD_AUTH_TOKEN | API key for the HackMD space | 
| ROLLING_IDEA_GENERATION_URL | Url of the HackMD for rolling topic generation, this is intentionally not public as it's only accessible to community members |
| ZOOM_LINK | The link of the zoom meeting, which includes the meeting id and passcode | 
| ZOOM_MEETING_ID | The meeting id for people who may need to paste it in |
| ZOOM_PASSCODE | The passcode for people who may need to paste it in |

Annoyingly Zoom don't describe how to generate the encoded passcode url parameter from the passcode, so you need all three of those things. 

We publish the HackMDs to the [cross gov software engineering HackMD account](https://hackmd.io/@uk-x-gov-software-community/).

They are intentionally not published in that account, they are only available to community members.
