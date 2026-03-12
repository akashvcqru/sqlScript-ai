# Login API Design Documentation

This document outlines the API structure for company authentication and service retrieval.

## Endpoint Details
- **Path**: `/api/Auth/CompanyLogin`
- **Method**: `POST`
- **Content-Type**: `application/json`

## Request Payload
```json
{
    "email": "bhabhra.sangeeta@mahindra.com",
    "password": "yourpasswordhere"
}
```

## Response Structure (Aggregated)
The backend logic maps the results from `USP_GetCompanyLoginDetails` into the following structure:

```json
{
    "success": true,
    "message": "Services fetched successfully.",
    "data": {
        "isPolicyAccepted": true,
        "services": [
            {
                "success": 1,
                "message": "Services fetched successfully.",
                "comp_ID": "Comp-1152",
                "service_ID": "SRV1005",
                "serviceName": "Cash Transfers"
            },
            {
                "success": 1,
                "message": "Services fetched successfully.",
                "comp_ID": "Comp-1152",
                "service_ID": "SRV1018",
                "serviceName": "COUNTERFIETING"
            }
        ]
    }
}
```

## Logic Mapping
- **`success`**: Maps from the result set of the Stored Procedure.
- **`isPolicyAccepted`**: Boolean representing if the company has records in `Tbl_UserPolicyAcceptance`.
- **`services`**: An array of objects joined from `M_ServiceSubscription` and `M_Service`.
- **Authentication**: Validation against `Comp_Reg.Comp_Email` and `Comp_Reg.Password`.
