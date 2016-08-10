Hybrid IT Live Demo
=====
ABC Group is an industry-changing entertainment media company. They currently employ the MS SharePoint platform as their collaborating tools. Now they want to leverage the exciting capability of the cloud computing to extend the performance and availability for their SharePoint system.
this demo will user AWS CloudFormation, EC2 and related resource

Author: Forest Zhang, Di,Yingwei, wesley

How it works
====

####Quick Mast template for On-premises DC: Demokit_HybridIT_OnPremises_QuickMaster_2015.template
----
##### Demokit_AD_GL_2015.template
        will create a VPC with:
        2xPublic Subnet
        2xPrivate Subnet
        1xNAT, and 1xBastion Host
        2xDomain controller and DNS server
        1xDomain(example: amazing.com)

##### Demokit_SQL_GL_2015.template
        will Create:
        2xSQL 2012 Standard Server Cluster with mirroring relationship

##### Demokit_VPN_GL_2015.template
        will Create:
        2xSQL 2012 Standard Server Cluster with mirroring relationship


####Quick Mast template for Cloud DC: Demokit_HybridIT_Cloud_QuickMaster_2015.template
----
##### Demokit_VPC_GL_2015.template
        VPC(here): will create a VPC with:
        2xPublic Subnet
        2xPrivate Subnet
        1xNAT

##### Demokit_SP_GL_2015.template
        will Create:
        2xSharePoint 2013 Cluster node
