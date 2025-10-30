export const handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    console.log('Hello World from SNS Lambda!');

    // Environment Variables verfügbar:
    console.log('SQS_QUEUE_URL:', process.env.SQS_QUEUE_URL);
    console.log('SQS_QUEUE_ARN:', process.env.SQS_QUEUE_ARN);
    console.log('S3_BUCKET_NAME:', process.env.S3_BUCKET_NAME);
    console.log('S3_BUCKET_ARN:', process.env.S3_BUCKET_ARN);
    console.log('SNS_TOPIC_ARN:', process.env.SNS_TOPIC_ARN);

    // TODO: Hier AWS SDK Code für SNS hinzufügen
    // Beispiel: import { SNSClient, PublishCommand } from "@aws-sdk/client-sns";

    return {
        statusCode: 200,
        body: JSON.stringify({
            message: 'Hello World from SNS Lambda!'
        })
    };
};
