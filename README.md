# crm-shared-timeline

[![Build](https://github.com/navikt/crm-shared-timeline/workflows/%5BPUSH%5D%20Create%20Package/badge.svg)](https://github.com/navikt/crm-shared-timeline/actions?query=workflow%3Acreate)
[![GitHub version](https://badgen.net/github/release/navikt/crm-shared-timeline/stable)](https://github.com/navikt/crm-shared-timeline)
[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/navikt/crm-shared-timeline/blob/master/LICENSE)

## Overview

LWC component based on the default Salesforce Activity Timeline, but extended to work with any Salesforce object.

![Timeline](/.img/timeline.png)

## Dependencies

-   [crm-thread-view](https://github.com/navikt/crm-thread-view)

## Configuration

You can easily configure which objects to be visible in a timeline, and you can even specify which Salesforce app the configuration is intended for.

|     Parent Config     |     Child Config     |
| :-------------------: | :------------------: |
| ![](/.img/parent.png) | ![](/.img/child.png) |

### Automatic Refresh on Record Create

You'll need to create a push topic for every SObject. Specify the push topic name in the Child Config. Create a push topic by running the following code (must also be done in production):

```java
String sobjectName = 'SOBJECT';

insert new PushTopic(Name = 'TIMELINE_' + sobjectName, Query = 'SELECT Id FROM ' + sobjectName, NotifyForOperationCreate = true, NotifyForFields = 'All', ApiVersion = 52.0);
```

### Limitations

-   The Expanded Fields To Display feature does not support all objects. See the User Interface API documentation for a list of supported objects. https://developer.salesforce.com/docs/atlas.en-us.uiapi.meta/uiapi/ui_api_list_view_supported_objects.

## Custom Views

To add a custom view for a child object:
1. Create a Controller class and Custom component
1. Update timelineCustomView component to show your custom component conditionaly
2. Mark 'Custom View' checkbox in your Timeline Child Config.

## Installation

1. Install [npm](https://nodejs.org/en/download/)
1. Install [Salesforce DX CLI](https://developer.salesforce.com/tools/sfdxcli)
    - Alternative: `npm install sfdx-cli --global`
1. Clone this repository ([GitHub Desktop](https://desktop.github.com) is recommended for non-developers)
1. Run `npm install` from the project root folder
1. Install [SSDX](https://github.com/navikt/ssdx)
    - **Non-developers may stop after this step**
1. Install [VS Code](https://code.visualstudio.com) (recommended)
    - Install [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)
    - **Install recommended plugins!** A notification should appear when opening VS Code. It will prompt you to install recommended plugins.
1. Install [AdoptOpenJDK](https://adoptopenjdk.net) (only version 8 or 11)
1. Open VS Code settings and search for `salesforcedx-vscode-apex`
1. Under `Java Home`, add the following:
    - macOS: `/Library/Java/JavaVirtualMachines/adoptopenjdk-[VERSION_NUMBER].jdk/Contents/Home`
    - Windows: `C:\\Program Files\\AdoptOpenJDK\\jdk-[VERSION_NUMBER]-hotspot`

## Build

To build locally without using SSDX, do the following:

1. If you haven't authenticated a DX user to production / DevHub, run `sfdx auth:web:login -d -a production` and log in
    - Ask `#crm-platform-team` on Slack if you don't have a user
    - If you change from one repo to another, you can change the default DevHub username in `.sfdx/sfdx-config.json`, but you can also just run the command above
1. Create a scratch org, install dependencies and push metadata:

```bash
sfdx force:org:create -f ./config/project-scratch-def.json --setalias scratch_org --durationdays 1 --setdefaultusername
echo y | sfdx plugins:install sfpowerkit@2.0.1
keys="" && for p in $(sfdx force:package:list --json | jq '.result | .[].Name' -r); do keys+=$p":{key} "; done
sfdx sfpowerkit:package:dependencies:install -u scratch_org -r -a -w 60 -k ${keys}
sfdx force:source:push
sfdx force:org:open
```

## Other

Questions? Ask on #crm-platform-team on Slack.
