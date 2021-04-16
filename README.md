# crm-shared-timeline

[![Build](https://github.com/navikt/crm-shared-timeline/workflows/%5BPUSH%5D%20Create%20Package/badge.svg)](https://github.com/navikt/crm-shared-timeline/actions?query=workflow%3Acreate)
[![GitHub version](https://badgen.net/github/release/navikt/crm-shared-timeline/stable)](https://github.com/navikt/crm-shared-timeline)
[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/navikt/crm-shared-timeline/blob/master/LICENSE)

## Overview

LWC component based on the default Salesforce Activity Timeline, but extended to work with any Salesforce object. 

![Timeline](/.img/timeline.png)

## Configuration

You can easily configure which objects to be visible in a timeline, and you can even specify which Salesforce app the configuration is intended for.

|     Parent Config     |     Child Config     |
|   :----------------:  |   :---------------:  |
| ![](/.img/parent.png) | ![](/.img/child.png) |

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

## Other

Questions? Ask on #crm-platform-team on Slack.
