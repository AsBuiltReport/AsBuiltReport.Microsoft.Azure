# culture = 'es-ES'
# NOTE: Only the AVD section (GetAbrAzDesktopVirtualization) is translated to Spanish.
# Other sections use English strings as fallback until translations are contributed.
@{

# Module-wide strings
InvokeAsBuiltReportMicrosoftAzure = ConvertFrom-StringData @'
    DefaultOrder = No custom section order specified. Using default order.
    CustomOrder = Using custom section order from report JSON configuration.
    Connecting = Connecting to Azure Tenant ID '{0}'.
    Subscriptions = Subscriptions
    SubscriptionID = Setting Azure context to Subscription ID '{0}'.
    InfoLevelNotFound = InfoLevel for '{0}' not found.
    FunctionNotFound = Function '{0}' for section '{1}' not found.
    SectionError = Error processing section '{0}': {1}"
    TenantNotFound = Azure Tenant '{0}' not found.
    TokenAccountIdRequired = Azure token authentication requires AccountId parameter. Use {0} with {1} @{{AccountId="user@domain.com"}}.
    ConnectingWithToken = Connecting to Azure using token for account {0} in tenant {1}.
'@

# Country Code to Country Name mapping (Get-CountryName)
GetCountryName = ConvertFrom-StringData @'
    CodeNotFound = Country code '{0}' not found.
    AF = Afghanistan
    AL = Albania
    DZ = Algeria
    AD = Andorra
    AO = Angola
    AR = Argentina
    AM = Armenia
    AU = Australia
    AT = Austria
    AZ = Azerbaijan
    BS = Bahamas
    BH = Bahrain
    BD = Bangladesh
    BB = Barbados
    BY = Belarus
    BE = Belgium
    BZ = Belize
    BJ = Benin
    BT = Bhutan
    BO = Bolivia
    BA = Bosnia and Herzegovina
    BW = Botswana
    BR = Brazil
    BN = Brunei
    BG = Bulgaria
    KH = Cambodia
    CM = Cameroon
    CA = Canada
    CL = Chile
    CN = China
    CO = Colombia
    CR = Costa Rica
    HR = Croatia
    CU = Cuba
    CY = Cyprus
    CZ = Czechia
    DK = Denmark
    DO = Dominican Republic
    EC = Ecuador
    EG = Egypt
    SV = El Salvador
    EE = Estonia
    ET = Ethiopia
    FI = Finland
    FR = France
    DE = Germany
    GH = Ghana
    GR = Greece
    GT = Guatemala
    HN = Honduras
    HK = Hong Kong SAR
    HU = Hungary
    IS = Iceland
    IN = India
    ID = Indonesia
    IR = Iran
    IQ = Iraq
    IE = Ireland
    IL = Israel
    IT = Italy
    JM = Jamaica
    JP = Japan
    JO = Jordan
    KZ = Kazakhstan
    KE = Kenya
    KR = Korea (South)
    KW = Kuwait
    LV = Latvia
    LB = Lebanon
    LY = Libya
    LT = Lithuania
    LU = Luxembourg
    MY = Malaysia
    MX = Mexico
    MA = Morocco
    NL = Netherlands
    NZ = New Zealand
    NG = Nigeria
    NO = Norway
    PK = Pakistan
    PA = Panama
    PY = Paraguay
    PE = Peru
    PH = Philippines
    PL = Poland
    PT = Portugal
    PR = Puerto Rico
    QA = Qatar
    RO = Romania
    RU = Russia
    SA = Saudi Arabia
    SG = Singapore
    SK = Slovakia
    SI = Slovenia
    ZA = South Africa
    ES = Spain
    LK = Sri Lanka
    SE = Sweden
    CH = Switzerland
    TW = Taiwan
    TH = Thailand
    TR = Turkiye
    UA = Ukraine
    AE = United Arab Emirates
    GB = United Kingdom
    US = United States
    UY = Uruguay
    VE = Venezuela
    VN = Vietnam
'@

# Azure Tenant Information (Get-AbrAzTenant)
GetAbrAzTenant = ConvertFrom-StringData @'
    InfoLevel = Tenant InfoLevel set at {0}.
    Collecting = Collecting Azure Tenant information.
    Heading = Tenant
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    TenantName = Tenant Name
    TenantID = Tenant ID
    TenantType = Tenant Type
    Country = Country
    Domains = Domains
    DefaultDomain = Default Domain
    TableHeading = Tenant
'@

# Azure Site Recovery Protected Items (Get-AbrAsrProtectedItems)
GetAbrAsrProtectedItems = ConvertFrom-StringData @'
    InfoLevel = SiteRecovery InfoLevel set at {0}.
    Collecting = Collecting Azure Site Recovery information '{0}'.
    CollectingItems = Collecting Azure Site Recovery Protected Items information.
    ParagraghSummary = The following tables provides information for the Azure Site Recovery protected items within the {0} subscription.
    Heading = Protected Items
    TableHeading = Protected Items
    SubHeading = Site Recovery
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    VirtualMachine = Virtual Machine
    ReplicationHealth = Replication Health
    State = State
    ActiveLocation = Active Location
    TargetLocation = Target Location
    FailoverHealth = Failover Health
'@

# Azure Availability Sets (Get-AbrAzAvailabilitySet)
GetAbrAzAvailabilitySet = ConvertFrom-StringData @'
    InfoLevel = AvailabilitySet InfoLevel set at {0}.
    Collecting = Collecting Azure Availability Set information.
    SectionInfo = An Availability Set (AS) is a logical construct to inform Azure that it should distribute contained virtual machine instances across multiple fault and update domains within an Azure region.
    ParagraphSummary = The following table summarizes the configuration of the availability sets within the {0} subscription.
    Heading = Availability Sets
    TableHeading = Availability Sets
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    SKU = SKU
    VirtualMachines = Virtual Machines
    None = None
'@

# Azure Bastion (Get-AbrAzBastion)
GetAbrAzBastion = ConvertFrom-StringData @'
    InfoLevel = Bastion InfoLevel set at {0}.
    Collecting = Collecting Azure Bastion information.
    SectionInfo1 = Azure Bastion is a service you deploy that lets you connect to a virtual machine using your browser and the Azure portal, or via the native SSH or RDP client already installed on your local computer.
    SectionInfo2 = The Azure Bastion service is a fully platform-managed PaaS service that you provision inside your virtual network. It provides secure and seamless RDP/SSH connectivity to your virtual machines directly from the Azure portal over TLS.
    SectionInfo3 = Bastion provides secure RDP and SSH connectivity to all of the VMs in the virtual network in which it is provisioned.
    ParagraphDetail = The following sections detail the configuration of the bastions within the {0} subscription.
    ParagraphSummary = The following table summarizes the configuration of the bastions within the {0} subscription.
    Heading = Bastion
    TableHeading = Bastion
    TableHeadings = Bastions
    Image = Bastion Architecture
    ImageError = Unable to display Bastion image.
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    ProvisioningState = Provisioning State
    VirtualNetworkSubnet = Virtual Network / Subnet
    PublicDnsName = Public DNS Name
    PublicIpAddress = Public IP Address
    Tags = Tags
    None = None
'@

# Azure DNS Private Resolver (Get-AbrAzDnsPrivateResolver)
GetAbrAzDnsPrivateResolver = ConvertFrom-StringData @'
    InfoLevel = DnsPrivateResolver InfoLevel set at {0}.
    Collecting = Collecting Azure DNS Private Resolver information.
    SectionInfo = Azure Private DNS Resolver is a service that securely resolves DNS queries for private resources in Azure VNets.
    ParagraphDetail = The following sections detail the configuration of the DNS private resolver(s) within the {0} subscription.
    ParagraphSummary = The following table summarizes the configuration of the DNS private resolver(s) within the {0} subscription.
    Heading = DNS Private Resolver
    TableHeading = Private DNS Resolver
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    InboundEndpoints = Inbound Endpoints
    OutboundEndpoints = Outbound Endpoints
    VirtualNetwork = Virtual Network
    ResourceGuid = Resource Guid
    CreationTime = Creation Time
    LastModified = Last Modified
    CurrentState = Current State
    ProvisioningState = Provisioning State
    EndpointName = Endpoint Name
    IpAddress = IP Address
    IpAllocation = IP Allocation
    Tags = Tags
    None = None
'@

# Azure Storage Account (Get-AbrAzStorageAccount)
GetAbrAzStorageAccount = ConvertFrom-StringData @'
    InfoLevel = StorageAccount InfoLevel set at {0}.
    Collecting = Collecting Azure Storage Account information.
    Processing = Processing Azure Storage Account '{0}' ({1} of {2}).
    SectionInfo = Azure storage account contains all of your Azure Storage data objects, including blobs, file shares, queues, tables, and disks.
    ParagraphDetail = The following sections detail the configuration of the storage account within the {0} subscription.
    ParagraphSummary = The following table summarizes the configuration of the storage account within the {0} subscription.
    Heading = Storage Account
    TableHeading = Storage Account
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    PrimarySecondaryLocation = Primary/Secondary Location
    Primary = Primary
    Secondary = Secondary
    DiskState = Disk state
    Performance = Performance
    Replication = Replication
    LRS = Locally-redundant storage (LRS)
    ZRS = Zone-redundant storage (ZRS)
    GRS = Geo-redundant storage (GRS)
    RAGRS = Read access geo-redundant storage (RA-GRS)
    PremiumLRS = Premium locally-redundant storage (Premium LRS)
    PremiumZRS = Premium zone-redundant storage (Premium ZRS)
    GZRS = Geo-redundant zone-redundant storage (GZRS)
    RAGZRS = Read access geo-redundant zone-redundant storage (RA-GZRS)
    AccountKind = Account Kind
    Storage = Storage (General Purpose v1)
    StorageV2 = StorageV2 (General Purpose v2)
    BlobStorage = Blob Storage
    BlockBlobStorage = Block Blob Storage
    FileStorage = File Storage
    ProvisioningState = Provisioning State
    SecureTransfer = Secure Transfer for REST API
    StorageAccountKeyAccess = Storage Account Key Access
    PublicNetworkAccess = Public Network Access
    MinimumTLSVersion = Minimum TLS Version
    InfrastructureEncryption = Infrastructure Encryption
    Enabled = Enabled
    Disabled = Disabled
    Unknown = Unknown
    Created = Created
    Tags = Tags
    None = None
'@

# Azure ExpressRoute Circuit (Get-AbrAzExpressRouteCircuit)
GetAbrAzExpressRouteCircuit = ConvertFrom-StringData @'
    InfoLevel = ExpressRoute InfoLevel set at {0}.
    Collecting = Collecting ExpressRoute Circuit information.
    SectionInfo = An ExpressRoute circuit allows a private dedicated connection into Azure with the help of a connectivity provider.
    ParagraphDetail = The following sections detail the configuration of the ExpressRoute circuits within the {0} subscription.
    ParagraphSummary = The following table summarizes the configuration of the ExpressRoute circuits within the {0} subscription.
    Heading = ExpressRoute Circuit
    TableHeading = ExpressRoute Circuit
    TableHeadings = ExpressRoute Circuits
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    CircuitStatus = Circuit Status
    Provider = Provider
    ProviderStatus = Provider Status
    PeeringLocation = Peering Location
    Bandwidth = Bandwidth
    ServiceKey = Service Key
    SKU = SKU
    BillingModel = Billing Model
    MeteredData = Metered
    AllowClassicOperations = Allow Classic Operations
    On = On
    Off = Off
    None = None
    Tags = Tags
'@

# Azure Firewall (Get-AbrAzFirewall)
GetAbrAzFirewall = ConvertFrom-StringData @'
    InfoLevel = Firewall InfoLevel set at {0}.
    Collecting = Collecting Azure Firewall information.
    SectionInfo = Azure Firewall is a managed, cloud-based network security service that protects your Azure Virtual Network resources.
    ParagraphDetail = The following sections detail the configuration of the firewalls within the {0} subscription.
    ParagraphSummary = The following table summarizes the configuration of the firewalls within the {0} subscription.
    Heading = Firewalls
    TableHeading = Firewall
    TableHeadings = Firewalls
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    FirewallPolicy = Firewall Policy
    ProvisioningState = Provisioning State
    SKU = SKU
    Subnet = Subnet
    PublicIP = Public IP
    PrivateIP = Private IP
    NatRuleCollections = NAT Rule Collections
    NetworkRuleCollections = Network Rule Collections
    ApplicationRuleCollections = Application Rule Collections
    NatRules = NAT Rules
    NetworkRules = Network Rules
    AppRules = Application Rules
    Tags = Tags
    None = None
'@

# Azure Firewall NAT Rules (Get-AbrAzFirewallNatRule)
GetAbrAzFirewallNatRule = ConvertFrom-StringData @'
    Collecting = Collecting Azure Firewall NAT Rule Collections information.
    Heading = NAT Rule Collections
    TableHeading = NAT Rule Collections
    Name = Name
    Priority = Priority
    Action = Action
    Rules = Rules
    Protocols = Protocols
    SourceType = Source Type
    IPAddress = IP Address
    IPGroup = IP Group
    Source = Source
    DestinationAddresses = Destination Addresses
    DestinationType = Destination Type
    TranslatedAddress = Translated Address
    TranslatedPort = Translated Port
    DestinationPorts = Destination Ports
    NatRule = NAT Rule
'@

# Azure Firewall Network Rules (Get-AbrAzFirewallNetworkRule)
GetAbrAzFirewallNetworkRule = ConvertFrom-StringData @'
    Collecting = Collecting Azure Firewall Network Rule Collections information.
    Heading = Network Rule Collections
    TableHeading = Network Rule Collections
    Name = Name
    Priority = Priority
    Action = Action
    Rules = Rules
    Protocols = Protocols
    SourceType = Source Type
    IPAddress = IP Address
    IPGroup = IP Group
    Source = Source
    DestinationType = Destination Type
    Destination = Destination
    DestinationPorts = Destination Ports
    NetworkAllowRule = Network Allow Rule
    NetworkDenyRule = Network Deny Rule
'@

# Azure Load Balancer Backend Pool (Get-AbrAzLbBackendPool)
GetAbrAzLbBackendPool = ConvertFrom-StringData @'
    Collecting = Collecting Azure Load Balancer Backend Pool information.
    Heading = Backend Pools
    TableHeading = Backend Pools
    Name = Name
    LoadBalancingRules = Load Balancing Rules
    None = None
'@

# Azure IP Group (Get-AbrAzIpGroup)
GetAbrAzIpGroup = ConvertFrom-StringData @'
    InfoLevel = IPGroup InfoLevel set at {0}.
    Collecting = Collecting Azure IP Group information.
    SectionInfo = Azure IP Groups allow you to group and manage IP addresses for Azure Firewall rules.
    ParagraphSummary = The following table summarizes the configuration of the IP Groups within the {0} subscription.
    ParagraphDetail = The following sections detail the configuration of the IP Groups within the {0} subscription.
    TableHeading = IP Group
    TableHeadings = IP Groups
    Heading = IP Groups
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    ProvisioningState = Provisioning State
    Firewalls = Firewalls
    IPAddresses = IP Addresses
    Tags = Tags
    None = None
'@

# Azure Key Vault (Get-AbrAzKeyVault)
GetAbrAzKeyVault = ConvertFrom-StringData @'
    InfoLevel = KeyVault InfoLevel set at {0}.
    Collecting = Collecting Azure Key Vault information.
    SectionInfo = Azure Key Vault is a key management solution which enables Azure users and applications to securely store and access keys, secrets, and certificates.
    ParagraphDetail = The following sections detail the configuration of the key vaults within the {0} subscription.
    ParagraphSummary = The following table summarizes the configuration of the key vaults within the {0} subscription.
    AzureVM = Azure Virtual Machines for Deployment
    AzureRM = Azure Resource Manager for Template Deployment
    ADE = Azure Disk Encryption for Volume Encryption
    Heading = Key Vaults
    TableHeading = Key Vault
    TableHeadings = Key Vaults
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    VaultURI = Vault URI
    SkuPricingTier = Sku (Pricing Tier)
    ResourceAccess = Resource Access
    RBACAuthorization = RBAC Authorization
    SoftDelete = Soft Delete
    PurgeProtection = Purge Protection
    PublicNetworkAccess = Public Network Access
    Enabled = Enabled
    Disabled = Disabled
    NoAccessEnabled = No access enabled
    EnabledDays = Enabled ({0} days)
    Tags = Tags
    None = None
    days = days
'@

# Azure Load Balancer Health Probe (Get-AbrAzLbHealthProbe)
GetAbrAzLbHealthProbe = ConvertFrom-StringData @'
    Collecting = Collecting Azure Load Balancer Health Probe information.
    Heading = Health Probes
    TableHeading = Health Probes
    Name = Name
    Protocol = Protocol
    Port = Port
    Interval = Interval
    UsedBy = Used By
    Seconds = {0} seconds
'@

# Azure Load Balancer Frontend IP Configuration (Get-AbrAzLbFrontendIpConfig)
GetAbrAzLbFrontendIpConfig = ConvertFrom-StringData @'
    Collecting = Collecting Azure Load Balancer Frontend IP Configuration information.
    Heading = Frontend IP Configuration
    TableHeading = Frontend IP Configuration
    Name = Name
    PrivateIPAddress = Private IP Address
    PrivateIPAllocationMethod = Private IP Allocation Method
    PublicIPAddress = Public IP Address
    Subnet = Subnet
    LoadBalancingRules = Load Balancing Rules
    InboundNATRules = Inbound NAT Rules
    None = None
    Unknown = Unknown
'@

# Azure Load Balancer Inbound NAT Pool (Get-AbrAzLbInboundNatPool)
GetAbrAzLbInboundNatPool = ConvertFrom-StringData @'
    Collecting = Collecting Azure Load Balancer Inbound NAT Pool information.
    Heading = Inbound NAT Pools
    TableHeading = Inbound NAT Pools
    Name = Name
'@

# Azure Load Balancer Load Balancing Rule (Get-AbrAzLbLoadBalancingRule)
GetAbrAzLbLoadBalancingRule = ConvertFrom-StringData @'
    Collecting = Collecting Azure Load Balancer Load Balancing Rules information.
    Heading = Load Balancing Rules
    TableHeading = Load Balancing Rule
    Name = Name
    FrontendIPAddress = Frontend IP Address
    BackendPool = Backend Pool
    Protocol = Protocol
    Port = Port
    BackendPort = Backend Port
    HealthProbe = Health Probe
    IdleTimeout = Idle Timeout
    FloatingIP = Floating IP
    Enabled = Enabled
    Disabled = Disabled
    Minutes = {0} minutes
'@

# Azure Load Balancer (Get-AbrAzLoadBalancer)
GetAbrAzLoadBalancer = ConvertFrom-StringData @'
    InfoLevel = LoadBalancer InfoLevel set at {0}.
    Collecting = Collecting Azure Load Balancer information.
    SectionInfo1 = Azure Load Balancer operates at layer 4 of the Open Systems Interconnection (OSI) model.
    SectionInfo2 = Azure Load Balancer supports two SKUs: Basic and Standard.
    SectionInfo3 = There are two types of Azure Load Balancer: Public and Internal.
    ParagraphDetail = The following sections detail the configuration of the load balancers within the {0} subscription.
    ParagraphSummary = The following table summarizes the configuration of the load balancers within the {0} subscription.
    Heading = Load Balancers
    TableHeading = Load Balancer
    TableHeadings = Load Balancers
    LoadBalancerImage = Load Balancer Image
    ImageError = Unable to display Load Balancer image
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    ProvisioningState = Provisioning State
    SKU = SKU
    Tier = Tier
    Standard = Standard
    Basic = Basic
    Type = Type
    Public = Public
    Internal = Internal
    FrontendIPConfigs = Frontend IP Configurations
    BackendPools = Backend Pools
    LoadBalancingRules = Load Balancing Rules
    HealthProbes = Health Probes
    InboundNATRules = Inbound NAT Rules
    InboundNATPools = Inbound NAT Pools
    Tags = Tags
    None = None
'@

# Azure Log Analytics Workspace (Get-AbrAzLogAnalyticsWorkspace)
GetAbrAzLogAnalyticsWorkspace = ConvertFrom-StringData @'
    InfoLevel = LogAnalyticsWorkspace InfoLevel set at {0}.
    Collecting = Collecting Azure Log Analytics Workspace information.
    SectionInfo = Azure Log Analytics is a service in Azure that collects, analyzes, and acts on telemetry data from cloud and on-premises environments.
    ParagraphDetail = The following sections detail the configuration of the log analytics workspaces within the {0} subscription.
    ParagraphSummary = The following table summarizes the configuration of the log analytics workspaces within the {0} subscription.
    Heading = Log Analytics Workspaces
    TableHeading = Log Analytics Workspaces
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    WorkspaceID = Workspace ID
    Sku = SKU
    RetentionDays = Retention (Days)
    DailyQuotaGB = Daily Quota
    ProvisioningState = Provisioning State
    PublicNetworkAccessForIngestion = Public Network Access (Ingestion)
    PublicNetworkAccessForQuery = Public Network Access (Query)
    Enabled = Enabled
    Disabled = Disabled
    Unknown = Unknown
    NoQuota = No Quota Set
    Tags = Tags
    None = None
'@

# Azure Network Security Group (Get-AbrAzNetworkSecurityGroup)
GetAbrAzNetworkSecurityGroup = ConvertFrom-StringData @'
    InfoLevel = NetworkSecurityGroup InfoLevel set at {0}.
    Collecting = Collecting Azure Network Security Group information.
    SectionInfo = An Azure Network Security Group (NSG) is used to filter network traffic to and from Azure resources in an Azure virtual network.
    ParagraphDetail = The following sections detail the configuration of the network security groups within the {0} subscription.
    ParagraphSummary = The following table summarizes the configuration of the network security groups within the {0} subscription.
    Image = Network Security Group Architecture
    ImageError = Unable to display Network Security Group image.
    Heading = Network Security Groups
    TableHeading = Network Security Group
    TableHeadings = Network Security Groups
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    ProvisioningState = Provisioning State
    AssociatedWith = Associated With
    NetworkInterfaces = Network Interfaces
    Subnets = Subnets
    Tags = Tags
    None = None
'@

# Azure Network Security Group Rules (Get-AbrAzNetworkSecurityGroupRule)
GetAbrAzNetworkSecurityGroupRule = ConvertFrom-StringData @'
    Collecting = Collecting Azure NSG Security Rules information.
    Heading1 = Inbound Security Rules
    TableHeading1 = Inbound Security Rules
    Heading2 = Outbound Security Rules
    TableHeading2 = Outbound Security Rules
    Priority = Priority
    Name = Name
    Port = Port
    Any = Any
    Protocol = Protocol
    Source = Source
    Destination = Destination
    Action = Action
'@

# Azure Policy (Get-AbrAzPolicy)
GetAbrAzPolicy = ConvertFrom-StringData @'
    InfoLevel = Policy InfoLevel set at 0.
    Collecting = Collecting Azure Policy information.
    Heading = Azure Policy
    SectionInfo = Azure Policy helps to enforce organisational standards and to assess compliance at-scale.
'@

# Azure Policy Assignments (Get-AbrAzPolicyAssignment)
GetAbrAzPolicyAssignment = ConvertFrom-StringData @'
    InfoLevel = Policy Assignments InfoLevel set at {0}.
    Collecting = Collecting Azure Policy Assignments information.
    ParagraphDetail = The following sections detail the policy assignments within the {0} subscription.
    ParagraphSummary = The following table summarizes the policy assignments within the {0} subscription.
    Heading = Policy Assignments
    TableHeading = Policy Assignment
    TableHeadings = Policy Assignments
    Name = Name
    Description = Description
    Location = Location
    Scope = Scope
    Type = Type
    ExcludedScopes = Excluded Scopes
    DefinitionType = Definition Type
    Policy = Policy
    Initiative = Initiative
    Unknown = Unknown
    PolicyEnforcement = Policy Enforcement
    Enforce = Enforce
    DoNotEnforce = Do Not Enforce
'@

# Azure Policy Definitions (Get-AbrAzPolicyDefinition)
GetAbrAzPolicyDefinition = ConvertFrom-StringData @'
    InfoLevel = Policy Definitions InfoLevel set at {0}.
    Collecting = Collecting Azure Policy Definition information.
    ParagraphSummary = The following table summarizes the policy definitions within the {0} subscription.
    Heading = Policy Definitions
    TableHeading = Policy Definitions
    TableHeadings = Policy Definitions
    Name = Name
    Version = Version
    Policies = Policies
    Type = Type
    DefinitionType = Definition Type
    Policy = Policy
    Initiative = Initiative
    Category = Category
'@

# Azure Private Endpoint (Get-AbrAzPrivateEndpoint)
GetAbrAzPrivateEndpoint = ConvertFrom-StringData @'
    InfoLevel = PrivateEndpoint InfoLevel set at {0}.
    Collecting = Collecting Azure Private Endpoint information.
    SectionInfo = An Azure Private Endpoint is a network interface that connects you privately and securely to a service powered by Azure Private Link.
    ParagraphDetail = The following sections detail the configuration of the private endpoints within the {0} subscription.
    ParagraphSummary = The following table summarizes the configuration of the private endpoints within the {0} subscription.
    Heading = Private Endpoints
    TableHeading = Private Endpoint
    TableHeadings = Private Endpoints
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    ProvisioningState = Provisioning State
    VirtualNetworkSubnet = Virtual Network / Subnet
    NetworkInterface = Network Interface
    PrivateLinkResource = Private Link Resource
    PrivateIP = Private IP
    TargetSubResource = Target Sub-Resource
    ConnectionStatus = Connection Status
    Response = Response
    Pending = Pending
    Rejected = Rejected
    Disconnected = Disconnected
    Tags = Tags
    None = None
'@

# Azure Recovery Services Vault (Get-AbrAzRecoveryServicesVault)
GetAbrAzRecoveryServicesVault = ConvertFrom-StringData @'
    InfoLevel = RecoveryServicesVault InfoLevel set at {0}.
    Collecting = Collecting Azure Recovery Services Vault information.
    SectionInfo = A Recovery Services vault is a storage entity in Azure that houses data.
    ParagraphDetail = The following sections detail the configuration of the recovery services vaults within the {0} subscription.
    ParagraphSummary = The following table summarizes the configuration of the recovery services vaults within the {0} subscription.
    Heading = Recovery Services Vaults
    TableHeading = Recovery Services Vault
    TableHeadings = Recovery Services Vaults
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    ProvisioningState = Provisioning State
    PrivateEndpointStateForBackup = Private Endpoint State for Backup
    PrivateEndpointStateForSiteRecovery = Private Endpoint State for Site Recovery
    Tags = Tags
    None = None
'@

# Azure Route Table (Get-AbrAzRouteTable)
GetAbrAzRouteTable = ConvertFrom-StringData @'
    InfoLevel = RouteTable InfoLevel set at {0}.
    Collecting = Collecting Azure Route Table information.
    SectionInfo = An Azure route table contains a collection of routes that are used to determine where network traffic is directed.
    ParagraphDetail = The following sections detail the configuration of the route tables within the {0} subscription.
    ParagraphSummary = The following table summarizes the configuration of the route tables within the {0} subscription.
    Heading = Route Tables
    TableHeading = Route Table
    TableHeadings = Route Tables
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    ProvisioningState = Provisioning State
    Routes = Routes
    AddressPrefix = Address Prefix
    NextHopType = Next Hop Type
    NextHopIpAddress = Next Hop IP Address
    Tags = Tags
    None = None
'@

# Azure Blob Storage Service Property (Get-AbrAzSABlobServiceProperty)
GetAbrAzSABlobServiceProperty = ConvertFrom-StringData @'
    Collecting = Collecting Azure Blob Storage Service Properties information '{0}'.
    Heading = Blob Service
    TableHeading = Blob Service
    HierarchicalNamespace = Hierarchical Namespace
    Enabled = Enabled
    Disabled = Disabled
    DefaultAccessTier = Default Access Tier
    NotApplicable = Not Applicable
    BlobAnonymousAccess = Blob Anonymous Access
    BlobSoftDelete = Blob Soft Delete
    ContainerSoftDelete = Container Soft Delete
    Versioning = Versioning
    ChangeFeed = Change Feed
    NfsV3 = NFS v3
    SFTP = SFTP
    AllowCrossTenantReplication = Allow Cross-Tenant Replication
    EnabledDays = Enabled ({0} days)
'@

# Azure Storage Account Containers (Get-AbrAzSAContainer)
GetAbrAzSAContainer = ConvertFrom-StringData @'
    Collecting = Collecting Azure Storage Account Container information.
    Processing = Processing Azure Storage Account Container '{0}' ({1} of {2}).
    Heading = Containers
    TableHeading = Containers
    Name = Name
    AnonymousAccessLevel = Anonymous Access Level
    Private = Private
    Blob = Blob
    Container = Container
    LeaseState = Lease State
    LastModified = Last Modified
    Disabled = Disabled
'@

# Azure Storage Account Tables (Get-AbrAzSATable)
GetAbrAzSATable = ConvertFrom-StringData @'
    Collecting = Collecting Azure Storage Account Table information.
    Processing = Processing Azure Storage Account Table '{0}' ({1} of {2}).
    Heading = Tables
    TableHeading = Tables
    Name = Name
'@

# Azure Storage Account Queues (Get-AbrAzSAQueue)
GetAbrAzSAQueue = ConvertFrom-StringData @'
    Collecting = Collecting Azure Storage Account Queue information.
    Processing = Processing Azure Storage Account Queue '{0}' ({1} of {2}).
    Heading = Queues
    TableHeading = Queues
    Name = Name
'@

# Azure Storage Account File Service Property (Get-AbrAzSAFileServiceProperty)
GetAbrAzSAFileServiceProperty = ConvertFrom-StringData @'
    Collecting = Collecting Azure File Storage Service Properties information '{0}'.
    Heading = File Service
    TableHeading = File Service
    LargeFileShare = Large File Share
    NotConfigured = Not configured
    Enabled = Enabled
    Disabled = Disabled
    IdentityBasedAccess = Identity Based Access
    SoftDelete = Soft Delete
    EnabledDays = Enabled ({0} days)
'@

# Azure Storage Account Share
GetAbrAzSAShare = ConvertFrom-StringData @'
    Collecting = Collecting Azure Storage Account Shares information.
    Processing = Processing Azure Storage Account Share '{0}' ({1} of {2}).
    Heading = Shares
    TableHeading = Shares
    Name = Name
    ShareUrl = Share URL
    Quota = Quota
    Unknown = Unknown
    AccessTier = Access Tier
    TransactionOptimized = Transaction Optimized
    LastModified = Last Modified
    Snapshot = Snapshot
    Enabled = Enabled
    Disabled = Disabled
'@

# Azure Subscription (Get-AbrAzSubscription)
GetAbrAzSubscription = ConvertFrom-StringData @'
    InfoLevel = Subscription InfoLevel set at {0}.
    Collecting = Collecting Azure Subscription information.
    Processing = Processing Azure Subscription '{0}' ({1} of {2}).
    Heading = Subscriptions
    SectionInfo = An Azure subscription is a logical container used to provision resources in Microsoft Azure.
    ParagraphSummary = The following table summarizes the configuration of the subscriptions within the {0} tenant.
    TableHeading = Subscriptions
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    SubscriptionID = Subscription ID
    State = State
    NoSubscriptions = No subscriptions found.
'@

# Azure Virtual Machine (Get-AbrAzVirtualMachine)
GetAbrAzVirtualMachine = ConvertFrom-StringData @'
    InfoLevel = VirtualMachine InfoLevel set at {0}.
    Collecting = Collecting Azure Virtual Machine information.
    Processing = Processing Azure Virtual Machine '{0}' ({1} of {2}).
    SectionInfo1 = An Azure Virtual Machine (VM) is a scalable computing resource that provides the flexibility of virtualization without the need to buy and maintain physical hardware.
    SectionInfo2 = Azure VMs offer various sizes and configurations to meet different workload requirements.
    ParagraphDetail = The following sections detail the configuration of the virtual machines within the {0} subscription.
    ParagraphSummary = The following table summarizes the configuration of the virtual machines within the {0} subscription.
    Heading = Virtual Machines
    TableHeading = Virtual Machine
    TableHeadings = Virtual Machines
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    Status = Status
    Deallocated = Deallocated
    Running = Running
    PrivateIPAddress = Private IP Address
    PrivateIPAssignment = Private IP Assignment
    VirtualNetworkSubnet = Virtual Network / Subnet
    OsType = OS Type
    Size = Size
    vCpus = vCPUs
    RAM = RAM
    OperatingSystem = Operating System
    CustomImage = Custom Image:
    OsDisk = OS Disk
    OSDiskSize = OS Disk Size
    OSDiskType = OS Disk Type
    Unknown = Unknown
    NoOfDataDisks = No. of Data Disks
    AzureDiskEncryption = Azure Disk Encryption
    Enabled = Enabled
    Disabled = Disabled
    BootDiagnostics = Boot Diagnostics
    ManagedStorageAccount = Enabled with managed storage account
    CustomStorageAccount = Enabled with custom storage account
    BootDiagnosticsStorageAccount = Boot Diagnostics Storage Account
    None = None
    AzureBackup = Azure Backup
    Extensions = Extensions
    Tags = Tags
'@

# Azure Virtual Network (Get-AbrAzVirtualNetwork)
GetAbrAzVirtualNetwork = ConvertFrom-StringData @'
    InfoLevel = VirtualNetwork InfoLevel set at {0}.
    Collecting = Collecting Azure Virtual Network information.
    Processing = Processing Azure Virtual Network '{0}' ({1} of {2}).
    SectionInfo = An Azure Virtual Network (VNet) is a fundamental building block for your private network in Azure.
    ParagraphDetail = The following sections detail the configuration of the virtual networks within the {0} subscription.
    ParagraphSummary = The following table summarizes the configuration of the virtual networks within the {0} subscription.
    Heading = Virtual Networks
    TableHeading = Virtual Network
    TableHeadings = Virtual Networks
    Peerings = Peerings
    PeeringsInfo = Virtual network peering enables you to seamlessly connect two or more Virtual Networks in Azure.
    SubnetsInfo = Subnets enable you to segment the virtual network into one or more sub-networks.
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    ProvisioningState = Provisioning State
    AddressSpace = Address Space
    Unknown = Unknown
    Subnets = Subnets
    DnsServers = DNS Servers
    Default = Default (Azure-provided)
    Tags = Tags
    None = None
'@

# Azure Virtual Network Peering (Get-AbrAzVirtualNetworkPeering)
GetAbrAzVirtualNetworkPeering = ConvertFrom-StringData @'
    Collecting = Collecting Azure Virtual Network Peering information.
    Processing = Processing Azure Virtual Network Peering '{0}' ({1} of {2}).
    Heading = Virtual Network Peerings
    TableHeading = Virtual Network Peerings
    Name = Name
    PeeringStatus = Peering Status
    PeeringState = Peering State
    Peer = Peer
    AddressSpace = Address Space
    GatewayTransit = Gateway Transit
    Enabled = Enabled
    Disabled = Disabled
    TrafficToRemoteVnet = Traffic to Remote VNet
    Allow = Allow
    BlockRemoteVnet = Block all traffic to the remote virtual network
    TrafficForwardedFromRemoteVnet = Traffic forwarded from Remote VNet
    BlockForwardedTraffic = Block traffic that originates from outside this network
    VnetGateway = VNet Gateway or Route Server
    UseRemoteVnetGateway = Use the remote virtual network's gateway or Route Server
    UseLocalVnetGateway = Use this virtual network's gateway or Route Server
    None = None
'@

GetAbrAzVirtualNetworkSubnet = ConvertFrom-StringData @'
    Collecting = Collecting Azure Virtual Network Subnet information.
    Processing = Processing Azure Virtual Network Subnet '{0}' ({1} of {2}).
    Heading = Subnets
    TableHeading = Subnet
    Name = Name
    AddressRange = Address Range
    NatGateway = NAT Gateway
    None = None
    NetworkSecurityGroup = Network Security Group
    RouteTable = Route Table
'@

GetAbrAzFirewallPolicy = ConvertFrom-StringData @'
    InfoLevel = FirewallPolicy InfoLevel set at {0}.
    Collecting = Collecting Azure Firewall policy information.
    SectionInfo = Azure Firewall Policy is a top-level resource that contains security and operational settings for Azure Firewall.
    Name = Name
    ResourceGroup = Resource Group
    Location = Location
    Subscription = Subscription
    SubscriptionID = Subscription ID
    ProvisioningState = Provisioning State
    ParentPolicy = Parent Policy
    PolicyTier = Policy Tier
    ThreatIntelMode = Threat Intel Mode
    IntrusionDetectionMode = Intrusion Detection Mode
    DnsServers = DNS Servers
    DnsProxy = DNS Proxy
    Priority = Priority
    Rules = Rules
    Action = Action
    InheritedFrom = Inherited From
    Description = Description
    SourceAddresses = Source Addresses
    SourceIpGroups = Source IP Groups
    DestinationAddresses = Destination Addresses
    DestinationIpGroups = Destination IP Groups
    DestinationFqdns = Destination FQDNs
    DestinationPorts = Destination Ports
    TranslatedAddress = Translated Address
    TranslatedPort = Translated Port
    TranslatedFqdn = Translated FQDN
    TargetFQDNs = Target FQDNs
    TargetUrls = Target URLs
    Protocols = Protocols
    WebCategories = Web Categories
    Heading = Firewall Policies
    RcgHeading = Rule Collection Groups
    RcgTableHeading = Rule Collection Groups
    RcTableHeading = Rule Collections
    AppRuleTableHeading = Application Rule
    NetRuleTableHeading = Network Rule
    DnatRuleTableHeading = DNAT Rule
    NoRuleCollections = No rule collections found in {0}.
    NoParentPolicy = Unable to retrieve parent policy.
    NoParentPolicyRCG = Unable to retrieve parent policy rule collection groups.
    TableHeading = Firewall Policy
    Alert = Alert
    Deny = Deny
    Found = Found {0} rule collection group(s) in {1} policy.
    NotFound = No rule collection groups found in {0} policy.
    NotSupported = Not supported with standard policy
    Tags = Tags
    None = None
    Enabled = Enabled
    Disabled = Disabled
    Off = Off
    Default = Default (Azure provided)
    Skipping = Skipping null rule collection group reference
'@

# Azure Virtual Desktop (Get-AbrAzDesktopVirtualization) - SPANISH TRANSLATION
GetAbrAzDesktopVirtualization = ConvertFrom-StringData @'
    InfoLevel = Nivel de informacion de DesktopVirtualization establecido en {0}.
    Collecting = Recopilando informacion de Azure Virtual Desktop.
    SectionInfo = Azure Virtual Desktop es un servicio de virtualizacion de escritorios y aplicaciones que se ejecuta en Azure. Permite a los usuarios conectarse a un escritorio completo o a aplicaciones publicadas desde practicamente cualquier lugar.
    HostPoolsSummary = La siguiente tabla resume los grupos de hosts en la suscripcion {0}.
    AppGroupsSummary = La siguiente tabla resume los grupos de aplicaciones en la suscripcion {0}.
    WorkspacesSummary = La siguiente tabla resume los espacios de trabajo AVD en la suscripcion {0}.
    ScalingPlansSummary = La siguiente tabla resume los planes de escalado en la suscripcion {0}.
    WarningNoSessionHosts = ADVERTENCIA: El grupo de hosts '{0}' no tiene hosts de sesion.
    WarningAtCapacity = ADVERTENCIA: El grupo de hosts '{0}' esta al maximo de capacidad ({1}/{2} sesiones).
    Heading = Azure Virtual Desktop
    HostPoolsHeading = Grupos de Hosts
    SessionHostsHeading = Hosts de Sesion
    ApplicationGroupsHeading = Grupos de Aplicaciones
    WorkspacesHeading = Espacios de Trabajo
    ScalingPlansHeading = Planes de Escalado
    RdpPropertiesHeading = Propiedades RDP Personalizadas
    AgentUpdateHeading = Configuracion de Actualizacion del Agente
    RegistrationHeading = Informacion de Registro
    ActiveSessionsHeading = Sesiones Activas
    PublishedAppsHeading = Aplicaciones Publicadas
    SchedulesHeading = Programaciones
    Name = Nombre
    FriendlyName = Nombre Descriptivo
    ResourceGroup = Grupo de Recursos
    Location = Ubicacion
    Type = Tipo
    Tags = Etiquetas
    TimeZone = Zona Horaria
    Description = Descripcion
    LoadBalancer = Balanceador de Carga
    MaxSessionLimit = Limite Maximo de Sesiones
    StartVMOnConnect = Iniciar VM al Conectar
    ValidationEnvironment = Entorno de Validacion
    Property = Propiedad
    Value = Valor
    UpdateType = Tipo de Actualizacion
    MaintenanceWindow = Ventana de Mantenimiento
    UseLocalTime = Usar Hora Local
    ExpirationTime = Fecha de Expiracion
    TokenStatus = Estado del Token
    Status = Estado
    HealthCheck = Comprobacion de Estado
    Sessions = Sesiones
    AllowNewSessions = Permitir Nuevas Sesiones
    OSVersion = Version del SO
    AgentVersion = Version del Agente
    LastHeartbeat = Ultimo Latido
    UpdateState = Estado de Actualizacion
    AssignedUser = Usuario Asignado
    UpdateError = Error de Actualizacion
    VMResourceId = ID de Recurso VM
    HealthChecks = Comprobaciones de Estado
    User = Usuario
    SessionHost = Host de Sesion
    State = Estado
    Application = Aplicacion
    CreateTime = Fecha de Creacion
    HostPool = Grupo de Hosts
    Workspace = Espacio de Trabajo
    FilePath = Ruta del Archivo
    CommandLine = Linea de Comandos
    ShowInPortal = Mostrar en Portal
    ApplicationGroups = Grupos de Aplicaciones
    PublicNetworkAccess = Acceso a Red Publica
    ExclusionTag = Etiqueta de Exclusion
    HostPoolType = Tipo de Grupo de Hosts
    HostPoolAssignments = Asignaciones de Grupo de Hosts
    Days = Dias
    RampUpStart = Inicio de Aumento
    PeakStart = Inicio de Pico
    RampDownStart = Inicio de Reduccion
    OffPeakStart = Inicio Fuera de Pico
    RampUpAction = Accion de Aumento
    RampUpMinPct = Min de Aumento %
    RampUpCapacityPct = Capacidad de Aumento %
    RampDownAction = Accion de Reduccion
    RampDownMinPct = Min de Reduccion %
    RampDownCapacityPct = Capacidad de Reduccion %
    OffPeakAction = Accion Fuera de Pico
    Healthy = Saludable
    Expired = Expirado
    Valid = Valido
    NoActiveToken = Sin Token Activo
    None = Ninguno
    Unassigned = Sin Asignar
    Allowed = Permitido
'@

}
