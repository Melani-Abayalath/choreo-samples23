import ballerina/http;
import ballerina/log;
import ballerinax/aws.s3;

// Configurable variables for AWS credentials and S3 bucket
configurable string accessKeyId = ?;
configurable string secretAccessKey = ?;
configurable string region = ?;
configurable string bucketName = ?;

// Initialize AWS S3 client configuration
s3:ConnectionConfig amazonS3Config = {
    accessKeyId: accessKeyId,
    secretAccessKey: secretAccessKey,
    region: region
};

// Create an AWS S3 client
s3:Client amazonS3Client = check new (amazonS3Config);

// Define the HTTP listener on port 8080 (Ensure this port is allowed in Choreo)
listener http:Listener s3Listener = new (8080);

// Define the HTTP service
service /s3 on s3Listener {
    // Resource to list objects in the specified S3 bucket
    resource function get listObjects(http:Request req) returns json|error {
        log:printInfo("Received request to list objects in bucket: " + bucketName);

        // Invoke the AWS S3 client's listObjects operation
        var listObjectsResponse = amazonS3Client->listObjects(bucketName);

        if (listObjectsResponse is s3:S3Object[]) {
            log:printInfo("Successfully retrieved objects from S3 bucket.");

            // Initialize a mutable JSON array to hold object details
            json[] objectList = [];

            // Iterate over each S3 object and construct JSON objects
            foreach var s3Object in listObjectsResponse {
                json obj = {
                    "objectName": s3Object.objectName,
                    "objectSize": s3Object.objectSize.toString()
                };
                objectList.push(obj);
            }

            // Construct the final JSON payload
            json payload = { "objects": objectList };

            // Log the payload (optional, for debugging)
            log:printInfo("Payload to be returned: " + payload.toJsonString());

            // Return the payload directly
            return payload;
        } else {
            log:printError("Failed to retrieve objects from S3 bucket. Error: " + listObjectsResponse.toString());

            // Return an error with a generic message
            return error("Internal Server Error");
        }
    }
}
