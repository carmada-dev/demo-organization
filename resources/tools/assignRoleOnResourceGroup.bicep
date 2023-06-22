targetScope = 'resourceGroup'

// ============================================================================================

param RoleNameOrId string
param PrincipalType string = 'ServicePrincipal'
param PrincipalIds array = []

// ============================================================================================

var BuiltInRoleDefinitions = [

  // General

  {
    role: 'Contributor'
    description: 'Grants full access to manage all resources, but does not allow you to assign roles in Azure RBAC, manage assignments in Azure Blueprints, or share image galleries.'
    id: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  }
  {
    role: 'Owner'
    description: 'Grants full access to manage all resources, including the ability to assign roles in Azure RBAC.'
    id: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  }
  {
    role: 'Reader'
    description: 'View all resources, but does not allow you to make any changes.'
    id: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  }
  {
    role: 'User Access Administrator'
    description: 'Lets you manage user access to Azure resources.'
    id: '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
  }

  // Compute

  {
    role: 'Classic Virtual Machine Contributor'
    description: 'Lets you manage classic virtual machines, but not access to them, and not the virtual network or storage account they\'re connected to.'
    id: 'd73bb868-a0df-4d4d-bd69-98a00b01fccb'
  }
  {
    role: 'Data Operator for Managed Disks'
    description: 'Provides permissions to upload data to empty managed disks, read, or export data of managed disks (not attached to running VMs) and snapshots using SAS URIs and Azure AD authentication.'
    id: '959f8984-c045-4866-89c7-12bf9737be2e'
  }
  {
    role: 'Disk Backup Reader'
    description: 'Provides permission to backup vault to perform disk backup.'
    id: '3e5e47e6-65f7-47ef-90b5-e5dd4d455f24'
  }
  {
    role: 'Disk Pool Operator'
    description: 'Provide permission to StoragePool Resource Provider to manage disks added to a disk pool.'
    id: '60fc6e62-5479-42d4-8bf4-67625fcc2840'
  }
  {
    role: 'Disk Restore Operator'
    description: 'Provides permission to backup vault to perform disk restore.'
    id: 'b50d9833-a0cb-478e-945f-707fcc997c13'
  }
  {
    role: 'Disk Snapshot Contributor'
    description: 'Provides permission to backup vault to manage disk snapshots.'
    id: '7efff54f-a5b4-42b5-a1c5-5411624893ce'
  }
  {
    role: 'Virtual Machine Administrator Login'
    description: 'View Virtual Machines in the portal and login as administrator'
    id: '1c0163c0-47e6-4577-8991-ea5c82e286e4'
  }
  {
    role: 'Virtual Machine Contributor'
    description: 'Create and manage virtual machines, manage disks, install and run software, reset password of the root user of the virtual machine using VM extensions, and manage local user accounts using VM extensions. This role does not grant you management access to the virtual network or storage account the virtual machines are connected to. This role does not allow you to assign roles in Azure RBAC.'
    id: '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
  }
  {
    role: 'Virtual Machine User Login'
    description: 'View Virtual Machines in the portal and login as a regular user.'
    id: 'fb879df8-f326-4884-b1cf-06f3ad86be52'
  }
  {
    role: 'Windows Admin Center Administrator Login'
    description: 'Let\'s you manage the OS of your resource via Windows Admin Center as an administrator.'
    id: 'a6333a3e-0164-44c3-b281-7a577aff287f'
  }

  // Networking

  {
    role: 'CDN Endpoint Contributor'
    description: 'Can manage CDN endpoints, but can\'t grant access to other users.'
    id: '426e0c7f-0c7e-4658-b36f-ff54d6c29b45'
  }
  {
    role: 'CDN Endpoint Reader'
    description: 'Can view CDN endpoints, but can\'t make changes.'
    id: '871e35f6-b5c1-49cc-a043-bde969a0f2cd'
  }
  {
    role: 'CDN Profile Contributor'
    description: 'Can manage CDN profiles and their endpoints, but can\'t grant access to other users.'
    id: 'ec156ff8-a8d1-4d15-830c-5b80698ca432'
  }
  {
    role: 'CDN Profile Reader'
    description: 'Can view CDN profiles and their endpoints, but can\'t make changes.'
    id: '8f96442b-4075-438f-813d-ad51ab4019af'
  }
  {
    role: 'Classic Network Contributor'
    description: 'Lets you manage classic networks, but not access to them.'
    id: 'b34d265f-36f7-4a0d-a4d4-e158ca92e90f'
  }
  {
    role: 'DNS Zone Contributor'
    description: 'Lets you manage DNS zones and record sets in Azure DNS, but does not let you control who has access to them.'
    id: 'befefa01-2a29-4197-83a8-272ff33ce314'
  }
  {
    role: 'Network Contributor'
    description: 'Lets you manage networks, but not access to them.'
    id: '4d97b98b-1d4f-4787-a291-c67834d212e7'
  }
  {
    role: 'Private DNS Zone Contributor'
    description: 'Lets you manage private DNS zone resources, but not the virtual networks they are linked to.'
    id: 'b12aa53e-6015-4669-85d0-8515ebb3ae7f'
  }
  {
    role: 'Traffic Manager Contributor'
    description: 'Lets you manage Traffic Manager profiles, but does not let you control who has access to them.'
    id: 'a4b10055-b0c7-44c2-b00f-c7b5b3550cf7'
  }

  // Storage

  {
    role: 'Avere Contributor'
    description: 'Can create and manage an Avere vFXT cluster.'
    id: '4f8fab4f-1852-4a58-a46a-8eaf358af14a'
  }
  {
    role: 'Avere Operator'
    description: 'Used by the Avere vFXT cluster to manage the cluster'
    id: 'c025889f-8102-4ebf-b32c-fc0c6f0c6bd9'
  }
  {
    role: 'Backup Contributor'
    description: 'Lets you manage backup service, but can\'t create vaults and give access to others'
    id: '5e467623-bb1f-42f4-a55d-6e525e11384b'
  }
  {
    role: 'Backup Operator'
    description: 'Lets you manage backup services, except removal of backup, vault creation and giving access to others'
    id: '00c29273-979b-4161-815c-10b084fb9324'
  }
  {
    role: 'Backup Reader'
    description: 'Can view backup services, but can\'t make changes'
    id: 'a795c7a0-d4a2-40c1-ae25-d81f01202912'
  }
  {
    role: 'Classic Storage Account Contributor'
    description: 'Lets you manage classic storage accounts, but not access to them.'
    id: '86e8f5dc-a6e9-4c67-9d15-de283e8eac25'
  }
  {
    role: 'Classic Storage Account Key Operator Service Role'
    description: 'Classic Storage Account Key Operators are allowed to list and regenerate keys on Classic Storage Accounts'
    id: '985d6b00-f706-48f5-a6fe-d0ca12fb668d'
  }
  {
    role: 'Data Box Contributor'
    description: 'Lets you manage everything under Data Box Service except giving access to others.'
    id: 'add466c9-e687-43fc-8d98-dfcf8d720be5'
  }
  {
    role: 'Data Box Reader'
    description: 'Lets you manage Data Box Service except creating order or editing order details and giving access to others.'
    id: '028f4ed7-e2a9-465e-a8f4-9c0ffdfdc027'
  }
  {
    role: 'Data Lake Analytics Developer'
    description: 'Lets you submit, monitor, and manage your own jobs but not create or delete Data Lake Analytics accounts.'
    id: '47b7735b-770e-4598-a7da-8b91488b4c88'
  }
  {
    role: 'Elastic SAN Owner'
    description: 'Allows for full access to all resources under Azure Elastic SAN including changing network security policies to unblock data path access'
    id: '80dcbedb-47ef-405d-95bd-188a1b4ac406'
  }
  {
    role: 'Elastic SAN Reader'
    description: 'Allows for control path read access to Azure Elastic SAN'
    id: 'af6a70f8-3c9f-4105-acf1-d719e9fca4ca'
  }
  {
    role: 'Elastic SAN Volume Group Owner'
    description: 'Allows for full access to a volume group in Azure Elastic SAN including changing network security policies to unblock data path access'
    id: 'a8281131-f312-4f34-8d98-ae12be9f0d23'
  }
  {
    role: 'Reader and Data Access'
    description: 'Lets you view everything but will not let you delete or create a storage account or contained resource. It will also allow read/write access to all data contained in a storage account via access to storage account keys.'
    id: 'c12c1c16-33a1-487b-954d-41c89c60f349'
  }
  {
    role: 'Storage Account Backup Contributor'
    description: 'Lets you perform backup and restore operations using Azure Backup on the storage account.'
    id: 'e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1'
  }
  {
    role: 'Storage Account Contributor'
    description: 'Permits management of storage accounts. Provides access to the account key, which can be used to access data via Shared Key authorization.'
    id: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
  }
  {
    role: 'Storage Account Key Operator Service Role'
    description: 'Permits listing and regenerating storage account access keys.'
    id: '81a9662b-bebf-436f-a333-f67b29880f12'
  }
  {
    role: 'Storage Blob Data Contributor'
    description: 'Read, write, and delete Azure Storage containers and blobs. To learn which actions are required for a given data operation, see Permissions for calling blob and queue data operations.'
    id: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  }
  {
    role: 'Storage Blob Data Owner'
    description: 'Provides full access to Azure Storage blob containers and data, including assigning POSIX access control. To learn which actions are required for a given data operation, see Permissions for calling blob and queue data operations.'
    id: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
  }
  {
    role: 'Storage Blob Data Reader'
    description: 'Read and list Azure Storage containers and blobs. To learn which actions are required for a given data operation, see Permissions for calling blob and queue data operations.'
    id: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
  }
  {
    role: 'Storage Blob Delegator'
    description: 'Get a user delegation key, which can then be used to create a shared access signature for a container or blob that is signed with Azure AD credentials. For more information, see Create a user delegation SAS.'
    id: 'db58b8e5-c6ad-4a2a-8342-4190687cbf4a'
  }
  {
    role: 'Storage File Data Privileged Contributor'
    description: 'Allows for read, write, delete, and modify ACLs on files/directories in Azure file shares by overriding existing ACLs/NTFS permissions. This role has no built-in equivalent on Windows file servers.'
    id: '69566ab7-960f-475b-8e7c-b3118f30c6bd'
  }
  {
    role: 'Storage File Data Privileged Reader'
    description: 'Allows for read access on files/directories in Azure file shares by overriding existing ACLs/NTFS permissions. This role has no built-in equivalent on Windows file servers.'
    id: 'b8eda974-7b85-4f76-af95-65846b26df6d'
  }
  {
    role: 'Storage File Data SMB Share Contributor'
    description: 'Allows for read, write, and delete access on files/directories in Azure file shares. This role has no built-in equivalent on Windows file servers.'
    id: '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'
  }
  {
    role: 'Storage File Data SMB Share Elevated Contributor'
    description: 'Allows for read, write, delete, and modify ACLs on files/directories in Azure file shares. This role is equivalent to a file share ACL of change on Windows file servers.'
    id: 'a7264617-510b-434b-a828-9731dc254ea7'
  }
  {
    role: 'Storage File Data SMB Share Reader'
    description: 'Allows for read access on files/directories in Azure file shares. This role is equivalent to a file share ACL of read on  Windows file servers.'
    id: 'aba4ae5f-2193-4029-9191-0cb91df5e314'
  }
  {
    role: 'Storage Queue Data Contributor'
    description: 'Read, write, and delete Azure Storage queues and queue messages. To learn which actions are required for a given data operation, see Permissions for calling blob and queue data operations.'
    id: '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
  }
  {
    role: 'Storage Queue Data Message Processor'
    description: 'Peek, retrieve, and delete a message from an Azure Storage queue. To learn which actions are required for a given data operation, see Permissions for calling blob and queue data operations.'
    id: '8a0f0c08-91a1-4084-bc3d-661d67233fed'
  }
  {
    role: 'Storage Queue Data Message Sender'
    description: 'Add messages to an Azure Storage queue. To learn which actions are required for a given data operation, see Permissions for calling blob and queue data operations.'
    id: 'c6a89b2d-59bc-44d0-9896-0f6e12d7b80a'
  }
  {
    role: 'Storage Queue Data Reader'
    description: 'Read and list Azure Storage queues and queue messages. To learn which actions are required for a given data operation, see Permissions for calling blob and queue data operations.'
    id: '19e7f393-937e-4f77-808e-94535e297925'
  }
  {
    role: 'Storage Table Data Contributor'
    description: 'Allows for read, write and delete access to Azure Storage tables and entities'
    id: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
  }
  {
    role: 'Storage Table Data Reader'
    description: 'Allows for read access to Azure Storage tables and entities'
    id: '76199698-9eea-4c19-bc75-cec21354c6b6'
  }
  
  // Web

  {
    role: 'Azure Maps Data Contributor'
    description: 'Grants access to read, write, and delete access to map related data from an Azure maps account.'
    id: '8f5e0ce6-4f7b-4dcf-bddf-e6f48634a204'
  }
  {
    role: 'Azure Maps Data Reader'
    description: 'Grants access to read map related data from an Azure maps account.'
    id: '423170ca-a8f6-4b0f-8487-9e4eb8f49bfa'
  }
  {
    role: 'Azure Spring Cloud Config Server Contributor'
    description: 'Allow read, write and delete access to Azure Spring Cloud Config Server'
    id: 'a06f5c24-21a7-4e1a-aa2b-f19eb6684f5b'
  }
  {
    role: 'Azure Spring Cloud Config Server Reader'
    description: 'Allow read access to Azure Spring Cloud Config Server'
    id: 'd04c6db6-4947-4782-9e91-30a88feb7be7'
  }
  {
    role: 'Azure Spring Cloud Data Reader'
    description: 'Allow read access to Azure Spring Cloud Data'
    id: 'b5537268-8956-4941-a8f0-646150406f0c'
  }
  {
    role: 'Azure Spring Cloud Service Registry Contributor'
    description: 'Allow read, write and delete access to Azure Spring Cloud Service Registry'
    id: 'f5880b48-c26d-48be-b172-7927bfa1c8f1'
  }
  {
    role: 'Azure Spring Cloud Service Registry Reader'
    description: 'Allow read access to Azure Spring Cloud Service Registry'
    id: 'cff1b556-2399-4e7e-856d-a8f754be7b65'
  }
  {
    role: 'Media Services Account Administrator'
    description: 'Create, read, modify, and delete Media Services accounts; read-only access to other Media Services resources.'
    id: '054126f8-9a2b-4f1c-a9ad-eca461f08466'
  }
  {
    role: 'Media Services Live Events Administrator'
    description: 'Create, read, modify, and delete Live Events, Assets, Asset Filters, and Streaming Locators; read-only access to other Media Services resources.'
    id: '532bc159-b25e-42c0-969e-a1d439f60d77'
  }
  {
    role: 'Media Services Media Operator'
    description: 'Create, read, modify, and delete Assets, Asset Filters, Streaming Locators, and Jobs; read-only access to other Media Services resources.'
    id: 'e4395492-1534-4db2-bedf-88c14621589c'
  }
  {
    role: 'Media Services Policy Administrator'
    description: 'Create, read, modify, and delete Account Filters, Streaming Policies, Content Key Policies, and Transforms; read-only access to other Media Services resources. Cannot create Jobs, Assets or Streaming resources.'
    id: 'c4bba371-dacd-4a26-b320-7250bca963ae'
  }
  {
    role: 'Media Services Streaming Endpoints Administrator'
    description: 'Create, read, modify, and delete Streaming Endpoints; read-only access to other Media Services resources.'
    id: '99dba123-b5fe-44d5-874c-ced7199a5804'
  }
  {
    role: 'Search Index Data Contributor'
    description: 'Grants full access to Azure Cognitive Search index data.'
    id: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
  }
  {
    role: 'Search Index Data Reader'
    description: 'Grants read access to Azure Cognitive Search index data.'
    id: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
  }
  {
    role: 'Search Service Contributor'
    description: 'Lets you manage Search services, but not access to them.'
    id: '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
  }
  {
    role: 'SignalR AccessKey Reader'
    description: 'Read SignalR Service Access Keys'
    id: '04165923-9d83-45d5-8227-78b77b0a687e'
  }
  {
    role: 'SignalR App Server'
    description: 'Lets your app server access SignalR Service with AAD auth options.'
    id: '420fcaa2-552c-430f-98ca-3264be4806c7'
  }
  {
    role: 'SignalR REST API Owner'
    description: 'Full access to Azure SignalR Service REST APIs'
    id: 'fd53cd77-2268-407a-8f46-7e7863d0f521'
  }
  {
    role: 'SignalR REST API Reader'
    description: 'Read-only access to Azure SignalR Service REST APIs'
    id: 'ddde6b66-c0df-4114-a159-3618637b3035'
  }
  {
    role: 'SignalR Service Owner'
    description: 'Full access to Azure SignalR Service REST APIs'
    id: '7e4f1700-ea5a-4f59-8f37-079cfe29dce3'
  }
  {
    role: 'SignalR/Web PubSub Contributor'
    description: 'Create, Read, Update, and Delete SignalR service resources'
    id: '8cf5e20a-e4b2-4e9d-b3a1-5ceb692c2761'
  }
  {
    role: 'Web Plan Contributor'
    description: 'Manage the web plans for websites. Does not allow you to assign roles in Azure RBAC.'
    id: '2cc479cb-7b4d-49a8-b449-8c00fd0f0a4b'
  }
  {
    role: 'Website Contributor'
    description: 'Manage websites, but not web plans. Does not allow you to assign roles in Azure RBAC.'
    id: 'de139f84-1756-47ae-9be6-808fbbe84772'
  }

  // Containers

  {
    role: 'AcrDelete'
    description: 'Delete repositories, tags, or manifests from a container registry.'
    id: 'c2f4ef07-c644-48eb-af81-4b1b4947fb11'
  }
  {
    role: 'AcrImageSigner'
    description: 'Push trusted images to or pull trusted images from a container registry enabled for content trust.'
    id: '6cef56e8-d556-48e5-a04f-b8e64114680f'
  }
  {
    role: 'AcrPull'
    description: 'Pull artifacts from a container registry.'
    id: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
  }
  {
    role: 'AcrPush'
    description: 'Push artifacts to or pull artifacts from a container registry.'
    id: '8311e382-0749-4cb8-b61a-304f252e45ec'
  }
  {
    role: 'AcrQuarantineReader'
    description: 'Pull quarantined images from a container registry.'
    id: 'cdda3590-29a3-44f6-95f2-9f980659eb04'
  }
  {
    role: 'AcrQuarantineWriter'
    description: 'Push quarantined images to or pull quarantined images from a container registry.'
    id: 'c8d4ff99-41c3-41a8-9f60-21dfdad59608'
  }
  {
    role: 'Azure Kubernetes Fleet Manager RBAC Admin'
    description: 'This role grants admin access - provides write permissions on most objects within a namespace, with the exception of ResourceQuota object and the namespace object itself. Applying this role at cluster scope will give access across all namespaces.'
    id: '434fb43a-c01c-447e-9f67-c3ad923cfaba'
  }
  {
    role: 'Azure Kubernetes Fleet Manager RBAC Cluster Admin'
    description: 'Lets you manage all resources in the fleet manager cluster.'
    id: '18ab4d3d-a1bf-4477-8ad9-8359bc988f69'
  }
  {
    role: 'Azure Kubernetes Fleet Manager RBAC Reader'
    description: 'Allows read-only access to see most objects in a namespace. It does not allow viewing roles or role bindings. This role does not allow viewing Secrets, since reading the contents of Secrets enables access to ServiceAccount credentials in the namespace, which would allow API access as any ServiceAccount in the namespace (a form of privilege escalation).  Applying this role at cluster scope will give access across all namespaces.'
    id: '30b27cfc-9c84-438e-b0ce-70e35255df80'
  }
  {
    role: 'Azure Kubernetes Fleet Manager RBAC Writer'
    description: 'Allows read/write access to most objects in a namespace. This role does not allow viewing or modifying roles or role bindings. However, this role allows accessing Secrets as any ServiceAccount in the namespace, so it can be used to gain the API access levels of any ServiceAccount in the namespace.  Applying this role at cluster scope will give access across all namespaces.'
    id: '5af6afb3-c06c-4fa4-8848-71a8aee05683'
  }
  {
    role: 'Azure Kubernetes Service Cluster Admin Role'
    description: 'List cluster admin credential action.'
    id: '0ab0b1a8-8aac-4efd-b8c2-3ee1fb270be8'
  }
  {
    role: 'Azure Kubernetes Service Cluster User Role'
    description: 'List cluster user credential action.'
    id: '4abbcc35-e782-43d8-92c5-2d3f1bd2253f'
  }
  {
    role: 'Azure Kubernetes Service Contributor Role'
    description: 'Grants access to read and write Azure Kubernetes Service clusters'
    id: 'ed7f3fbd-7b88-4dd4-9017-9adb7ce333f8'
  }
  {
    role: 'Azure Kubernetes Service RBAC Admin'
    description: 'Lets you manage all resources under cluster/namespace, except update or delete resource quotas and namespaces.'
    id: '3498e952-d568-435e-9b2c-8d77e338d7f7'
  }
  {
    role: 'Azure Kubernetes Service RBAC Cluster Admin'
    description: 'Lets you manage all resources in the cluster.'
    id: 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'
  }
  {
    role: 'Azure Kubernetes Service RBAC Reader'
    description: 'Allows read-only access to see most objects in a namespace. It does not allow viewing roles or role bindings. This role does not allow viewing Secrets, since reading the contents of Secrets enables access to ServiceAccount credentials in the namespace, which would allow API access as any ServiceAccount in the namespace (a form of privilege escalation). Applying this role at cluster scope will give access across all namespaces.'
    id: '7f6c6a51-bcf8-42ba-9220-52d62157d7db'
  }
  {
    role: 'Azure Kubernetes Service RBAC Writer'
    description: 'Allows read/write access to most objects in a namespace. This role does not allow viewing or modifying roles or role bindings. However, this role allows accessing Secrets and running Pods as any ServiceAccount in the namespace, so it can be used to gain the API access levels of any ServiceAccount in the namespace. Applying this role at cluster scope will give access across all namespaces.'
    id: 'a7ffa36f-339b-4b5c-8bdf-e2c188b2c0eb'
  }

  // Databases

  {
    role: 'Azure Connected SQL Server Onboarding'
    description: 'Allows for read and write access to Azure resources for SQL Server on Arc-enabled servers.'
    id: 'e8113dce-c529-4d33-91fa-e9b972617508'
  }
  {
    role: 'Cosmos DB Account Reader Role'
    description: 'Can read Azure Cosmos DB account data. See DocumentDB Account Contributor for managing Azure Cosmos DB accounts.'
    id: 'fbdf93bf-df7d-467e-a4d2-9458aa1360c8'
  }
  {
    role: 'Cosmos DB Operator'
    description: 'Lets you manage Azure Cosmos DB accounts, but not access data in them. Prevents access to account keys and connection strings.'
    id: '230815da-be43-4aae-9cb4-875f7bd000aa'
  }
  {
    role: 'CosmosBackupOperator'
    description: 'Can submit restore request for a Cosmos DB database or a container for an account'
    id: 'db7b14f2-5adf-42da-9f96-f2ee17bab5cb'
  }
  {
    role: 'CosmosRestoreOperator'
    description: 'Can perform restore action for Cosmos DB database account with continuous backup mode'
    id: '5432c526-bc82-444a-b7ba-57c5b0b5b34f'
  }
  {
    role: 'DocumentDB Account Contributor'
    description: 'Can manage Azure Cosmos DB accounts. Azure Cosmos DB is formerly known as DocumentDB.'
    id: '5bd9cd88-fe45-4216-938b-f97437e15450'
  }
  {
    role: 'Redis Cache Contributor'
    description: 'Lets you manage Redis caches, but not access to them.'
    id: 'e0f68234-74aa-48ed-b826-c38b57376e17'
  }
  {
    role: 'SQL DB Contributor'
    description: 'Lets you manage SQL databases, but not access to them. Also, you can\'t manage their security-related policies or their parent SQL servers.'
    id: '9b7fa17d-e63e-47b0-bb0a-15c516ac86ec'
  }
  {
    role: 'SQL Managed Instance Contributor'
    description: 'Lets you manage SQL Managed Instances and required network configuration, but can\'t give access to others.'
    id: '4939a1f6-9ae0-4e48-a1e0-f2cbe897382d'
  }
  {
    role: 'SQL Security Manager'
    description: 'Lets you manage the security-related policies of SQL servers and databases, but not access to them.'
    id: '056cd41c-7e88-42e1-933e-88ba6a50c9c3'
  }
  {
    role: 'SQL Server Contributor'
    description: 'Lets you manage SQL servers and databases, but not access to them, and not their security-related policies.'
    id: '6d8ee4ec-f05a-4a1d-8b00-a9b17e38b437'
  }

  // Analytics
  
  {
    role: 'Azure Event Hubs Data Owner'
    description: 'Allows for full access to Azure Event Hubs resources.'
    id: 'f526a384-b230-433a-b45c-95f59c4a2dec'
  }
  {
    role: 'Azure Event Hubs Data Receiver'
    description: 'Allows receive access to Azure Event Hubs resources.'
    id: 'a638d3c7-ab3a-418d-83e6-5f17a39d4fde'
  }
  {
    role: 'Azure Event Hubs Data Sender'
    description: 'Allows send access to Azure Event Hubs resources.'
    id: '2b629674-e913-4c01-ae53-ef4638d8f975'
  }
  {
    role: 'Data Factory Contributor'
    description: 'Create and manage data factories, as well as child resources within them.'
    id: '673868aa-7521-48a0-acc6-0f60742d39f5'
  }
  {
    role: 'Data Purger'
    description: 'Delete private data from a Log Analytics workspace.'
    id: '150f5e0c-0603-4f03-8c7f-cf70034c4e90'
  }
  {
    role: 'HDInsight Cluster Operator'
    description: 'Lets you read and modify HDInsight cluster configurations.'
    id: '61ed4efc-fab3-44fd-b111-e24485cc132a'
  }
  {
    role: 'HDInsight Domain Services Contributor'
    description: 'Can Read, Create, Modify and Delete Domain Services related operations needed for HDInsight Enterprise Security Package'
    id: '8d8d5a11-05d3-4bda-a417-a08778121c7c'
  }
  {
    role: 'Log Analytics Contributor'
    description: 'Log Analytics Contributor can read all monitoring data and edit monitoring settings. Editing monitoring settings includes adding the VM extension to VMs; reading storage account keys to be able to configure collection of logs from Azure Storage; adding solutions; and configuring Azure diagnostics on all Azure resources.'
    id: '92aaf0da-9dab-42b6-94a3-d43ce8d16293'
  }
  {
    role: 'Log Analytics Reader'
    description: 'Log Analytics Reader can view and search all monitoring data as well as and view monitoring settings, including viewing the configuration of Azure diagnostics on all Azure resources.'
    id: '73c42c96-874c-492b-b04d-ab87d138a893'
  }
  {
    role: 'Schema Registry Contributor (Preview)'
    description: 'Read, write, and delete Schema Registry groups and schemas.'
    id: '5dffeca3-4936-4216-b2bc-10343a5abb25'
  }
  {
    role: 'Schema Registry Reader (Preview)'
    description: 'Read and list Schema Registry groups and schemas.'
    id: '2c56ea50-c6b3-40a6-83c0-9d98858bc7d2'
  }
  {
    role: 'Stream Analytics Query Tester'
    description: 'Lets you perform query testing without creating a stream analytics job first'
    id: '1ec5b3c1-b17e-4e25-8312-2acb3c3c5abf'
  }
  
  // AI + machine learning
  
  {
    role: 'AzureML Data Scientist'
    description: 'Can perform all actions within an Azure Machine Learning workspace, except for creating or deleting compute resources and modifying the workspace itself.'
    id: 'f6c7c914-8db3-469d-8ca1-694a8f32e121'
  }
  {
    role: 'Cognitive Services Contributor'
    description: 'Lets you create, read, update, delete and manage keys of Cognitive Services.'
    id: '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68'
  }
  {
    role: 'Cognitive Services Custom Vision Contributor'
    description: 'Full access to the project, including the ability to view, create, edit, or delete projects.'
    id: 'c1ff6cc2-c111-46fe-8896-e0ef812ad9f3'
  }
  {
    role: 'Cognitive Services Custom Vision Deployment'
    description: 'Publish, unpublish or export models. Deployment can view the project but can\'t update.'
    id: '5c4089e1-6d96-4d2f-b296-c1bc7137275f'
  }
  {
    role: 'Cognitive Services Custom Vision Labeler'
    description: 'View, edit training images and create, add, remove, or delete the image tags. Labelers can view the project but can\'t update anything other than training images and tags.'
    id: '88424f51-ebe7-446f-bc41-7fa16989e96c'
  }
  {
    role: 'Cognitive Services Custom Vision Reader'
    description: 'Read-only actions in the project. Readers can\'t create or update the project.'
    id: '93586559-c37d-4a6b-ba08-b9f0940c2d73'
  }
  {
    role: 'Cognitive Services Custom Vision Trainer'
    description: 'View, edit projects and train the models, including the ability to publish, unpublish, export the models. Trainers can\'t create or delete the project.'
    id: '0a5ae4ab-0d65-4eeb-be61-29fc9b54394b'
  }
  {
    role: 'Cognitive Services Data Reader (Preview)'
    description: 'Lets you read Cognitive Services data.'
    id: 'b59867f0-fa02-499b-be73-45a86b5b3e1c'
  }
  {
    role: 'Cognitive Services Face Recognizer'
    description: 'Lets you perform detect, verify, identify, group, and find similar operations on Face API. This role does not allow create or delete operations, which makes it well suited for endpoints that only need inferencing capabilities, following \'least privilege\' best practices.'
    id: '9894cab4-e18a-44aa-828b-cb588cd6f2d7'
  }
  {
    role: 'Cognitive Services Metrics Advisor Administrator'
    description: 'Full access to the project, including the system level configuration.'
    id: 'cb43c632-a144-4ec5-977c-e80c4affc34a'
  }
  {
    role: 'Cognitive Services OpenAI Contributor'
    description: 'Full access including the ability to fine-tune, deploy and generate text'
    id: 'a001fd3d-188f-4b5d-821b-7da978bf7442'
  }
  {
    role: 'Cognitive Services OpenAI User'
    description: 'Read access to view files, models, deployments. The ability to create completion and embedding calls.'
    id: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
  }
  {
    role: 'Cognitive Services QnA Maker Editor'
    description: 'Let\'s you create, edit, import and export a KB. You cannot publish or delete a KB.'
    id: 'f4cc2bf9-21be-47a1-bdf1-5c5804381025'
  }
  {
    role: 'Cognitive Services QnA Maker Reader'
    description: 'Let\'s you read and test a KB only.'
    id: '466ccd10-b268-4a11-b098-b4849f024126'
  }
  {
    role: 'Cognitive Services User'
    description: 'Lets you read and list keys of Cognitive Services.'
    id: 'a97b65f3-24c7-4388-baec-2e87135dc908'
  }
  
  // Internet of things
  
  {
    role: 'Device Update Administrator'
    description: 'Gives you full access to management and content operations'
    id: '02ca0879-e8e4-47a5-a61e-5c618b76e64a'
  }
  {
    role: 'Device Update Content Administrator'
    description: 'Gives you full access to content operations'
    id: '0378884a-3af5-44ab-8323-f5b22f9f3c98'
  }
  {
    role: 'Device Update Content Reader'
    description: 'Gives you read access to content operations, but does not allow making changes'
    id: 'd1ee9a80-8b14-47f0-bdc2-f4a351625a7b'
  }
  {
    role: 'Device Update Deployments Administrator'
    description: 'Gives you full access to management operations'
    id: 'e4237640-0e3d-4a46-8fda-70bc94856432'
  }
  {
    role: 'Device Update Deployments Reader'
    description: 'Gives you read access to management operations, but does not allow making changes'
    id: '49e2f5d2-7741-4835-8efa-19e1fe35e47f'
  }
  {
    role: 'Device Update Reader'
    description: 'Gives you read access to management and content operations, but does not allow making changes'
    id: 'e9dba6fb-3d52-4cf0-bce3-f06ce71b9e0f'
  }
  {
    role: 'IoT Hub Data Contributor'
    description: 'Allows for full access to IoT Hub data plane operations.'
    id: '4fc6c259-987e-4a07-842e-c321cc9d413f'
  }
  {
    role: 'IoT Hub Data Reader'
    description: 'Allows for full read access to IoT Hub data-plane properties'
    id: 'b447c946-2db7-41ec-983d-d8bf3b1c77e3'
  }
  {
    role: 'IoT Hub Registry Contributor'
    description: 'Allows for full access to IoT Hub device registry.'
    id: '4ea46cd5-c1b2-4a8e-910b-273211f9ce47'
  }
  {
    role: 'IoT Hub Twin Contributor'
    description: 'Allows for read and write access to all IoT Hub device and module twins.'
    id: '494bdba2-168f-4f31-a0a1-191d2f7c028c'
  }
  
  // Mixed reality
  
  {
    role: 'Remote Rendering Administrator'
    description: 'Provides user with conversion, manage session, rendering and diagnostics capabilities for Azure Remote Rendering'
    id: '3df8b902-2a6f-47c7-8cc5-360e9b272a7e'
  }
  {
    role: 'Remote Rendering Client'
    description: 'Provides user with manage session, rendering and diagnostics capabilities for Azure Remote Rendering.'
    id: 'd39065c4-c120-43c9-ab0a-63eed9795f0a'
  }
  {
    role: 'Spatial Anchors Account Contributor'
    description: 'Lets you manage spatial anchors in your account, but not delete them'
    id: '8bbe83f1-e2a6-4df7-8cb4-4e04d4e5c827'
  }
  {
    role: 'Spatial Anchors Account Owner'
    description: 'Lets you manage spatial anchors in your account, including deleting them'
    id: '70bbe301-9835-447d-afdd-19eb3167307c'
  }
  {
    role: 'Spatial Anchors Account Reader'
    description: 'Lets you locate and read properties of spatial anchors in your account'
    id: '5d51204f-eb77-4b1c-b86a-2ec626c49413'
  }
  
  // Integration
  
  {
    role: 'API Management Service Contributor'
    description: 'Can manage service and the APIs'
    id: '312a565d-c81f-4fd8-895a-4e21e48d571c'
  }
  {
    role: 'API Management Service Operator Role'
    description: 'Can manage service but not the APIs'
    id: 'e022efe7-f5ba-4159-bbe4-b44f577e9b61'
  }
  {
    role: 'API Management Service Reader Role'
    description: 'Read-only access to service and APIs'
    id: '71522526-b88f-4d52-b57f-d31fc3546d0d'
  }
  {
    role: 'API Management Service Workspace API Developer'
    description: 'Has read access to tags and products and write access to allow: assigning APIs to products, assigning tags to products and APIs. This role should be assigned on the service scope.'
    id: '9565a273-41b9-4368-97d2-aeb0c976a9b3'
  }
  {
    role: 'API Management Service Workspace API Product Manager'
    description: 'Has the same access as API Management Service Workspace API Developer as well as read access to users and write access to allow assigning users to groups. This role should be assigned on the service scope.'
    id: 'd59a3e9c-6d52-4a5a-aeed-6bf3cf0e31da'
  }
  {
    role: 'API Management Workspace API Developer'
    description: 'Has read access to entities in the workspace and read and write access to entities for editing APIs. This role should be assigned on the workspace scope.'
    id: '56328988-075d-4c6a-8766-d93edd6725b6'
  }
  {
    role: 'API Management Workspace API Product Manager'
    description: 'Has read access to entities in the workspace and read and write access to entities for publishing APIs. This role should be assigned on the workspace scope.'
    id: '73c2c328-d004-4c5e-938c-35c6f5679a1f'
  }
  {
    role: 'API Management Workspace Contributor'
    description: 'Can manage the workspace and view, but not modify its members. This role should be assigned on the workspace scope.'
    id: '0c34c906-8d99-4cb7-8bb7-33f5b0a1a799'
  }
  {
    role: 'API Management Workspace Reader'
    description: 'Has read-only access to entities in the workspace. This role should be assigned on the workspace scope.'
    id: 'ef1c2c96-4a77-49e8-b9a4-6179fe1d2fd2'
  }
  {
    role: 'App Configuration Data Owner'
    description: 'Allows full access to App Configuration data.'
    id: '5ae67dd6-50cb-40e7-96ff-dc2bfa4b606b'
  }
  {
    role: 'App Configuration Data Reader'
    description: 'Allows read access to App Configuration data.'
    id: '516239f1-63e1-4d78-a4de-a74fb236a071'
  }
  {
    role: 'Azure Relay Listener'
    description: 'Allows for listen access to Azure Relay resources.'
    id: '26e0b698-aa6d-4085-9386-aadae190014d'
  }
  {
    role: 'Azure Relay Owner'
    description: 'Allows for full access to Azure Relay resources.'
    id: '2787bf04-f1f5-4bfe-8383-c8a24483ee38'
  }
  {
    role: 'Azure Relay Sender'
    description: 'Allows for send access to Azure Relay resources.'
    id: '26baccc8-eea7-41f1-98f4-1762cc7f685d'
  }
  {
    role: 'Azure Service Bus Data Owner'
    description: 'Allows for full access to Azure Service Bus resources.'
    id: '090c5cfd-751d-490a-894a-3ce6f1109419'
  }
  {
    role: 'Azure Service Bus Data Receiver'
    description: 'Allows for receive access to Azure Service Bus resources.'
    id: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
  }
  {
    role: 'Azure Service Bus Data Sender'
    description: 'Allows for send access to Azure Service Bus resources.'
    id: '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
  }
  {
    role: 'Azure Stack Registration Owner'
    description: 'Lets you manage Azure Stack registrations.'
    id: '6f12a6df-dd06-4f3e-bcb1-ce8be600526a'
  }
  {
    role: 'EventGrid Contributor'
    description: 'Lets you manage EventGrid operations.'
    id: '1e241071-0855-49ea-94dc-649edcd759de'
  }
  {
    role: 'EventGrid Data Sender'
    description: 'Allows send access to event grid events.'
    id: 'd5a91429-5739-47e2-a06b-3470a27159e7'
  }
  {
    role: 'EventGrid EventSubscription Contributor'
    description: 'Lets you manage EventGrid event subscription operations.'
    id: '428e0ff0-5e57-4d9c-a221-2c70d0e0a443'
  }
  {
    role: 'EventGrid EventSubscription Reader'
    description: 'Lets you read EventGrid event subscriptions.'
    id: '2414bbcf-6497-4faf-8c65-045460748405'
  }
  {
    role: 'FHIR Data Contributor'
    description: 'Role allows user or principal full access to FHIR Data'
    id: '5a1fc7df-4bf1-4951-a576-89034ee01acd'
  }
  {
    role: 'FHIR Data Importer'
    description: 'Role allows user or principal to read and import FHIR Data'
    id: '4465e953-8ced-4406-a58e-0f6e3f3b530b'
  }
  {
    role: 'FHIR Data Exporter'
    description: 'Role allows user or principal to read and export FHIR Data'
    id: '3db33094-8700-4567-8da5-1501d4e7e843'
  }
  {
    role: 'FHIR Data Reader'
    description: 'Role allows user or principal to read FHIR Data'
    id: '4c8d0bbc-75d3-4935-991f-5f3c56d81508'
  }
  {
    role: 'FHIR Data Writer'
    description: 'Role allows user or principal to read and write FHIR Data'
    id: '3f88fce4-5892-4214-ae73-ba5294559913'
  }
  {
    role: 'Integration Service Environment Contributor'
    description: 'Lets you manage integration service environments, but not access to them.'
    id: 'a41e2c5b-bd99-4a07-88f4-9bf657a760b8'
  }
  {
    role: 'Integration Service Environment Developer'
    description: 'Allows developers to create and update workflows, integration accounts and API connections in integration service environments.'
    id: 'c7aa55d3-1abb-444a-a5ca-5e51e485d6ec'
  }
  {
    role: 'Intelligent Systems Account Contributor'
    description: 'Lets you manage Intelligent Systems accounts, but not access to them.'
    id: '03a6d094-3444-4b3d-88af-7477090a9e5e'
  }
  {
    role: 'Logic App Contributor'
    description: 'Lets you manage logic apps, but not change access to them.'
    id: '87a39d53-fc1b-424a-814c-f7e04687dc9e'
  }
  {
    role: 'Logic App Operator'
    description: 'Lets you read, enable, and disable logic apps, but not edit or update them.'
    id: '515c2055-d9d4-4321-b1b9-bd0c9a0f79fe'
  }
  
  // Identity
  
  {
    role: 'Domain Services Contributor'
    description: 'Can manage Azure AD Domain Services and related network configurations'
    id: 'eeaeda52-9324-47f6-8069-5d5bade478b2'
  }
  {
    role: 'Domain Services Reader'
    description: 'Can view Azure AD Domain Services and related network configurations'
    id: '361898ef-9ed1-48c2-849c-a832951106bb'
  }
  {
    role: 'Managed Identity Contributor'
    description: 'Create, Read, Update, and Delete User Assigned Identity'
    id: 'e40ec5ca-96e0-45a2-b4ff-59039f2c2b59'
  }
  {
    role: 'Managed Identity Operator'
    description: 'Read and Assign User Assigned Identity'
    id: 'f1a07417-d97a-45cb-824c-7a7467783830'
  }

  // Security
  
  {
    role: 'App Compliance Automation Administrator'
    description: 'Create, read, download, modify and delete reports objects and related other resource objects.'
    id: '0f37683f-2463-46b6-9ce7-9b788b988ba2'
  }
  {
    role: 'App Compliance Automation Reader'
    description: 'Read, download the reports objects and related other resource objects.'
    id: 'ffc6bbe0-e443-4c3b-bf54-26581bb2f78e'
  }
  {
    role: 'Attestation Contributor'
    description: 'Can read write or delete the attestation provider instance'
    id: 'bbf86eb8-f7b4-4cce-96e4-18cddf81d86e'
  }
  {
    role: 'Attestation Reader'
    description: 'Can read the attestation provider properties'
    id: 'fd1bd22b-8476-40bc-a0bc-69b95687b9f3'
  }
  {
    role: 'Key Vault Administrator'
    description: 'Perform all data plane operations on a key vault and all objects in it, including certificates, keys, and secrets. Cannot manage key vault resources or manage role assignments. Only works for key vaults that use the \'Azure role-based access control\' permission model.'
    id: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
  }
  {
    role: 'Key Vault Certificates Officer'
    description: 'Perform any action on the certificates of a key vault, except manage permissions. Only works for key vaults that use the \'Azure role-based access control\' permission model.'
    id: 'a4417e6f-fecd-4de8-b567-7b0420556985'
  }
  {
    role: 'Key Vault Contributor'
    description: 'Manage key vaults, but does not allow you to assign roles in Azure RBAC, and does not allow you to access secrets, keys, or certificates.'
    id: 'f25e0fa2-a7c8-4377-a976-54943a77a395'
  }
  {
    role: 'Key Vault Crypto Officer'
    description: 'Perform any action on the keys of a key vault, except manage permissions. Only works for key vaults that use the \'Azure role-based access control\' permission model.'
    id: '14b46e9e-c2b7-41b4-b07b-48a6ebf60603'
  }
  {
    role: 'Key Vault Crypto Service Encryption User'
    description: 'Read metadata of keys and perform wrap/unwrap operations. Only works for key vaults that use the \'Azure role-based access control\' permission model.'
    id: 'e147488a-f6f5-4113-8e2d-b22465e65bf6'
  }
  {
    role: 'Key Vault Crypto User'
    description: 'Perform cryptographic operations using keys. Only works for key vaults that use the \'Azure role-based access control\' permission model.'
    id: '12338af0-0e69-4776-bea7-57ae8d297424'
  }
  {
    role: 'Key Vault Reader'
    description: 'Read metadata of key vaults and its certificates, keys, and secrets. Cannot read sensitive values such as secret contents or key material. Only works for key vaults that use the \'Azure role-based access control\' permission model.'
    id: '21090545-7ca7-4776-b22c-e363652d74d2'
  }
  {
    role: 'Key Vault Secrets Officer'
    description: 'Perform any action on the secrets of a key vault, except manage permissions. Only works for key vaults that use the \'Azure role-based access control\' permission model.'
    id: 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
  }
  {
    role: 'Key Vault Secrets User'
    description: 'Read secret contents. Only works for key vaults that use the \'Azure role-based access control\' permission model.'
    id: '4633458b-17de-408a-b874-0445c86b69e6'
  }
  {
    role: 'Managed HSM contributor'
    description: 'Lets you manage managed HSM pools, but not access to them.'
    id: '18500a29-7fe2-46b2-a342-b16a415e101d'
  }
  {
    role: 'Microsoft Sentinel Automation Contributor'
    description: 'Microsoft Sentinel Automation Contributor'
    id: 'f4c81013-99ee-4d62-a7ee-b3f1f648599a'
  }
  {
    role: 'Microsoft Sentinel Contributor'
    description: 'Microsoft Sentinel Contributor'
    id: 'ab8e14d6-4a74-4a29-9ba8-549422addade'
  }
  {
    role: 'Microsoft Sentinel Playbook Operator'
    description: 'Microsoft Sentinel Playbook Operator'
    id: '51d6186e-6489-4900-b93f-92e23144cca5'
  }
  {
    role: 'Microsoft Sentinel Reader'
    description: 'Microsoft Sentinel Reader'
    id: '8d289c81-5878-46d4-8554-54e1e3d8b5cb'
  }
  {
    role: 'Microsoft Sentinel Responder'
    description: 'Microsoft Sentinel Responder'
    id: '3e150937-b8fe-4cfb-8069-0eaf05ecd056'
  }
  {
    role: 'Security Admin'
    description: 'View and update permissions for Microsoft Defender for Cloud. Same permissions as the Security Reader role and can also update the security policy and dismiss alerts and recommendations.\n\nFor Microsoft Defender for IoT, see Azure user roles for OT and Enterprise IoT monitoring.'
    id: 'fb1c8493-542b-48eb-b624-b4c8fea62acd'
  }
  {
    role: 'Security Assessment Contributor'
    description: 'Lets you push assessments to Microsoft Defender for Cloud'
    id: '612c2aa1-cb24-443b-ac28-3ab7272de6f5'
  }
  {
    role: 'Security Manager (Legacy)'
    description: 'This is a legacy role. Please use Security Admin instead.'
    id: 'e3d13bf0-dd5a-482e-ba6b-9b8433878d10'
  }
  {
    role: 'Security Reader'
    description: 'View permissions for Microsoft Defender for Cloud. Can view recommendations, alerts, a security policy, and security states, but cannot make changes.\n\nFor Microsoft Defender for IoT, see Azure user roles for OT and Enterprise IoT monitoring.'
    id: '39bc4728-0917-49c7-9d2c-d95423bc2eb4'
  }
  
  // DevOps
  
  {
    role: 'DevTest Labs User'
    description: 'Lets you connect, start, restart, and shutdown your virtual machines in your Azure DevTest Labs.'
    id: '76283e04-6283-4c54-8f91-bcf1374a3c64'
  }
  {
    role: 'Lab Assistant'
    description: 'Enables you to view an existing lab, perform actions on the lab VMs and send invitations to the lab.'
    id: 'ce40b423-cede-4313-a93f-9b28290b72e1'
  }
  {
    role: 'Lab Contributor'
    description: 'Applied at lab level, enables you to manage the lab. Applied at a resource group, enables you to create and manage labs.'
    id: '5daaa2af-1fe8-407c-9122-bba179798270'
  }
  {
    role: 'Lab Creator'
    description: 'Lets you create new labs under your Azure Lab Accounts.'
    id: 'b97fb8bc-a8b2-4522-a38b-dd33c7e65ead'
  }
  {
    role: 'Lab Operator'
    description: 'Gives you limited ability to manage existing labs.'
    id: 'a36e6959-b6be-4b12-8e9f-ef4b474d304d'
  }
  {
    role: 'Lab Services Contributor'
    description: 'Enables you to fully control all Lab Services scenarios in the resource group.'
    id: 'f69b8690-cc87-41d6-b77a-a4bc3c0a966f'
  }
  {
    role: 'Lab Services Reader'
    description: 'Enables you to view, but not change, all lab plans and lab resources.'
    id: '2a5c394f-5eb7-4d4f-9c8e-e8eae39faebc'
  }
  
  // Monitor

  {
    role: 'Application Insights Component Contributor'
    description: 'Can manage Application Insights components'
    id: 'ae349356-3a1b-4a5e-921d-050484c6347e'
  }
  {
    role: 'Application Insights Snapshot Debugger'
    description: 'Gives user permission to view and download debug snapshots collected with the Application Insights Snapshot Debugger. Note that these permissions are not included in the Owner or Contributor roles. When giving users the Application Insights Snapshot Debugger role, you must grant the role directly to the user. The role is not recognized when it is added to a custom role.'
    id: '08954f03-6346-4c2e-81c0-ec3a5cfae23b'
  }
  {
    role: 'Monitoring Contributor'
    description: 'Can read all monitoring data and edit monitoring settings. See also Get started with roles, permissions, and security with Azure Monitor.'
    id: '749f88d5-cbae-40b8-bcfc-e573ddc772fa'
  }
  {
    role: 'Monitoring Metrics Publisher'
    description: 'Enables publishing metrics against Azure resources'
    id: '3913510d-42f4-4e42-8a64-420c390055eb'
  }
  {
    role: 'Monitoring Reader'
    description: 'Can read all monitoring data (metrics, logs, etc.). See also Get started with roles, permissions, and security with Azure Monitor.'
    id: '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
  }
  {
    role: 'Workbook Contributor'
    description: 'Can save shared workbooks.'
    id: 'e8ddcd69-c73f-4f9f-9844-4100522f16ad'
  }
  {
    role: 'Workbook Reader'
    description: 'Can read workbooks.'
    id: 'b279062a-9be3-42a0-92ae-8b3cf002ec4d'
  }
  
  // Management and governance

  {
    role: 'Automation Contributor'
    description: 'Manage Azure Automation resources and other resources using Azure Automation.'
    id: 'f353d9bd-d4a6-484e-a77a-8050b599b867'
  }
  {
    role: 'Automation Job Operator'
    description: 'Create and Manage Jobs using Automation Runbooks.'
    id: '4fe576fe-1146-4730-92eb-48519fa6bf9f'
  }
  {
    role: 'Automation Operator'
    description: 'Automation Operators are able to start, stop, suspend, and resume jobs'
    id: 'd3881f73-407a-4167-8283-e981cbba0404'
  }
  {
    role: 'Automation Runbook Operator'
    description: 'Read Runbook properties - to be able to create Jobs of the runbook.'
    id: '5fb5aef8-1081-4b8e-bb16-9d5d0385bab5'
  }
  {
    role: 'Azure Arc Enabled Kubernetes Cluster User Role'
    description: 'List cluster user credentials action.'
    id: '00493d72-78f6-4148-b6c5-d3ce8e4799dd'
  }
  {
    role: 'Azure Arc Kubernetes Admin'
    description: 'Lets you manage all resources under cluster/namespace, except update or delete resource quotas and namespaces.'
    id: 'dffb1e0c-446f-4dde-a09f-99eb5cc68b96'
  }
  {
    role: 'Azure Arc Kubernetes Cluster Admin'
    description: 'Lets you manage all resources in the cluster.'
    id: '8393591c-06b9-48a2-a542-1bd6b377f6a2'
  }
  {
    role: 'Azure Arc Kubernetes Viewer'
    description: 'Lets you view all resources in cluster/namespace, except secrets.'
    id: '63f0a09d-1495-4db4-a681-037d84835eb4'
  }
  {
    role: 'Azure Arc Kubernetes Writer'
    description: 'Lets you update everything in cluster/namespace, except (cluster)roles and (cluster)role bindings.'
    id: '5b999177-9696-4545-85c7-50de3797e5a1'
  }
  {
    role: 'Azure Connected Machine Onboarding'
    description: 'Can onboard Azure Connected Machines.'
    id: 'b64e21ea-ac4e-4cdf-9dc9-5b892992bee7'
  }
  {
    role: 'Azure Connected Machine Resource Administrator'
    description: 'Can read, write, delete and re-onboard Azure Connected Machines.'
    id: 'cd570a14-e51a-42ad-bac8-bafd67325302'
  }
  {
    role: 'Billing Reader'
    description: 'Allows read access to billing data'
    id: 'fa23ad8b-c56e-40d8-ac0c-ce449e1d2c64'
  }
  {
    role: 'Blueprint Contributor'
    description: 'Can manage blueprint definitions, but not assign them.'
    id: '41077137-e803-4205-871c-5a86e6a753b4'
  }
  {
    role: 'Blueprint Operator'
    description: 'Can assign existing published blueprints, but cannot create new blueprints. Note that this only works if the assignment is done with a user-assigned managed identity.'
    id: '437d2ced-4a38-4302-8479-ed2bcb43d090'
  }
  {
    role: 'Cost Management Contributor'
    description: 'Can view costs and manage cost configuration (e.g. budgets, exports)'
    id: '434105ed-43f6-45c7-a02f-909b2ba83430'
  }
  {
    role: 'Cost Management Reader'
    description: 'Can view cost data and configuration (e.g. budgets, exports)'
    id: '72fafb9e-0641-4937-9268-a91bfd8191a3'
  }
  {
    role: 'Hierarchy Settings Administrator'
    description: 'Allows users to edit and delete Hierarchy Settings'
    id: '350f8d15-c687-4448-8ae1-157740a3936d'
  }
  {
    role: 'Kubernetes Cluster - Azure Arc Onboarding'
    description: 'Role definition to authorize any user/service to create connectedClusters resource'
    id: '34e09817-6cbe-4d01-b1a2-e0eac5743d41'
  }
  {
    role: 'Kubernetes Extension Contributor'
    description: 'Can create, update, get, list and delete Kubernetes Extensions, and get extension async operations'
    id: '85cb6faf-e071-4c9b-8136-154b5a04f717'
  }
  {
    role: 'Managed Application Contributor Role'
    description: 'Allows for creating managed application resources.'
    id: '641177b8-a67a-45b9-a033-47bc880bb21e'
  }
  {
    role: 'Managed Application Operator Role'
    description: 'Lets you read and perform actions on Managed Application resources'
    id: 'c7393b34-138c-406f-901b-d8cf2b17e6ae'
  }
  {
    role: 'Managed Applications Reader'
    description: 'Lets you read resources in a managed app and request JIT access.'
    id: 'b9331d33-8a36-4f8c-b097-4f54124fdb44'
  }
  {
    role: 'Managed Services Registration assignment Delete Role'
    description: 'Managed Services Registration Assignment Delete Role allows the managing tenant users to delete the registration assignment assigned to their tenant.'
    id: '91c1777a-f3dc-4fae-b103-61d183457e46'
  }
  {
    role: 'Management Group Contributor'
    description: 'Management Group Contributor Role'
    id: '5d58bcaf-24a5-4b20-bdb6-eed9f69fbe4c'
  }
  {
    role: 'Management Group Reader'
    description: 'Management Group Reader Role'
    id: 'ac63b705-f282-497d-ac71-919bf39d939d'
  }
  {
    role: 'New Relic APM Account Contributor'
    description: 'Lets you manage New Relic Application Performance Management accounts and applications, but not access to them.'
    id: '5d28c62d-5b37-4476-8438-e587778df237'
  }
  {
    role: 'Policy Insights Data Writer (Preview)'
    description: 'Allows read access to resource policies and write access to resource component policy events.'
    id: '66bb4e9e-b016-4a94-8249-4c0511c2be84'
  }
  {
    role: 'Quota Request Operator'
    description: 'Read and create quota requests, get quota request status, and create support tickets.'
    id: '0e5f05e5-9ab9-446b-b98d-1e2157c94125'
  }
  {
    role: 'Reservation Purchaser'
    description: 'Lets you purchase reservations'
    id: 'f7b75c60-3036-4b75-91c3-6b41c27c1689'
  }
  {
    role: 'Resource Policy Contributor'
    description: 'Users with rights to create/modify resource policy, create support ticket and read resources/hierarchy.'
    id: '36243c78-bf99-498c-9df9-86d9f8d28608'
  }
  {
    role: 'Site Recovery Contributor'
    description: 'Lets you manage Site Recovery service except vault creation and role assignment'
    id: '6670b86e-a3f7-4917-ac9b-5d6ab1be4567'
  }
  {
    role: 'Site Recovery Operator'
    description: 'Lets you failover and failback but not perform other Site Recovery management operations'
    id: '494ae006-db33-4328-bf46-533a6560a3ca'
  }
  {
    role: 'Site Recovery Reader'
    description: 'Lets you view Site Recovery status but not perform other management operations'
    id: 'dbaa88c4-0c30-4179-9fb3-46319faa6149'
  }
  {
    role: 'Support Request Contributor'
    description: 'Lets you create and manage Support requests'
    id: 'cfd33db0-3dd1-45e3-aa9d-cdbdf3b6f24e'
  }
  {
    role: 'Tag Contributor'
    description: 'Lets you manage tags on entities, without providing access to the entities themselves.'
    id: '4a9ae827-6dc8-4573-8ac7-8239d42aa03f'
  }
  {
    role: 'Template Spec Contributor'
    description: 'Allows full access to Template Spec operations at the assigned scope.'
    id: '1c9b6475-caf0-4164-b5a1-2142a7116f4b'
  }
  {
    role: 'Template Spec Reader'
    description: 'Allows read access to Template Specs at the assigned scope.'
    id: '392ae280-861d-42bd-9ea5-08ee6d83b80e'
  }
  
  // Virtual desktop infrastructure
  
  {
    role: 'Desktop Virtualization Application Group Contributor'
    description: 'Contributor of the Desktop Virtualization Application Group.'
    id: '86240b0e-9422-4c43-887b-b61143f32ba8'
  }
  {
    role: 'Desktop Virtualization Application Group Reader'
    description: 'Reader of the Desktop Virtualization Application Group.'
    id: 'aebf23d0-b568-4e86-b8f9-fe83a2c6ab55'
  }
  {
    role: 'Desktop Virtualization Contributor'
    description: 'Contributor of Desktop Virtualization.'
    id: '082f0a83-3be5-4ba1-904c-961cca79b387'
  }
  {
    role: 'Desktop Virtualization Host Pool Contributor'
    description: 'Contributor of the Desktop Virtualization Host Pool.'
    id: 'e307426c-f9b6-4e81-87de-d99efb3c32bc'
  }
  {
    role: 'Desktop Virtualization Host Pool Reader'
    description: 'Reader of the Desktop Virtualization Host Pool.'
    id: 'ceadfde2-b300-400a-ab7b-6143895aa822'
  }
  {
    role: 'Desktop Virtualization Reader'
    description: 'Reader of Desktop Virtualization.'
    id: '49a72310-ab8d-41df-bbb0-79b649203868'
  }
  {
    role: 'Desktop Virtualization Session Host Operator'
    description: 'Operator of the Desktop Virtualization Session Host.'
    id: '2ad6aaab-ead9-4eaa-8ac5-da422f562408'
  }
  {
    role: 'Desktop Virtualization User'
    description: 'Allows user to use the applications in an application group.'
    id: '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'
  }
  {
    role: 'Desktop Virtualization User Session Operator'
    description: 'Operator of the Desktop Virtualization User Session.'
    id: 'ea4bfff8-7fb4-485a-aadd-d4129a0ffaa6'
  }
  {
    role: 'Desktop Virtualization Workspace Contributor'
    description: 'Contributor of the Desktop Virtualization Workspace.'
    id: '21efdde3-836f-432b-bf3d-3e8e734d4b2b'
  }
  {
    role: 'Desktop Virtualization Workspace Reader'
    description: 'Reader of the Desktop Virtualization Workspace.'
    id: '0fa44ee9-7a7d-466b-9bb2-2bf446b1204d'
  }
  
  // Other
  
  {
    role: 'Azure Digital Twins Data Owner'
    description: 'Full access role for Digital Twins data-plane'
    id: 'bcd981a7-7f74-457b-83e1-cceb9e632ffe'
  }
  {
    role: 'Azure Digital Twins Data Reader'
    description: 'Read-only role for Digital Twins data-plane properties'
    id: 'd57506d4-4c8d-48b1-8587-93c323f6a5a3'
  }
  {
    role: 'BizTalk Contributor'
    description: 'Lets you manage BizTalk services, but not access to them.'
    id: '5e3c6656-6cfa-4708-81fe-0de47ac73342'
  }
  {
    role: 'Grafana Admin'
    description: 'Perform all Grafana operations, including the ability to manage data sources, create dashboards, and manage role assignments within Grafana.'
    id: '22926164-76b3-42b3-bc55-97df8dab3e41'
  }
  {
    role: 'Grafana Editor'
    description: 'View and edit a Grafana instance, including its dashboards and alerts.'
    id: 'a79a5197-3a5c-4973-a920-486035ffd60f'
  }
  {
    role: 'Grafana Viewer'
    description: 'View a Grafana instance, including its dashboards and alerts.'
    id: '60921a7e-fef1-4a43-9b16-a26c52ad4769'
  }
  {
    role: 'Load Test Contributor'
    description: 'View, create, update, delete and execute load tests. View and list load test resources but can not make any changes.'
    id: '749a398d-560b-491b-bb21-08924219302e'
  }
  {
    role: 'Load Test Owner'
    description: 'Execute all operations on load test resources and load tests'
    id: '45bb0b16-2f0c-4e78-afaa-a07599b003f6'
  }
  {
    role: 'Load Test Reader'
    description: 'View and list all load tests and load test resources but can not make any changes'
    id: '3ae3fb29-0000-4ccd-bf80-542e7b26e081'
  }
  {
    role: 'Scheduler Job Collections Contributor'
    description: 'Lets you manage Scheduler job collections, but not access to them.'
    id: '188a0f2f-5c9e-469b-ae67-2aa5ce574b94'
  }
  {
    role: 'Services Hub Operator'
    description: 'Services Hub Operator allows you to perform all read, write, and deletion operations related to Services Hub Connectors.'
    id: '82200a5b-e217-47a5-b665-6d8765ee745b'
  }
]

// ============================================================================================

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: length(filter(BuiltInRoleDefinitions, rd => rd.role == RoleNameOrId)) == 1 ? filter(BuiltInRoleDefinitions, rd => rd.role == RoleNameOrId)[0].id : RoleNameOrId
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = [for principalId in PrincipalIds: {
  name: guid(resourceGroup().id, roleDefinition.id, principalId)
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: principalId
    principalType: PrincipalType
  }
}]