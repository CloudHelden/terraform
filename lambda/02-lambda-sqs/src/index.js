const { SQSClient, SendMessageCommand } = require("@aws-sdk/client-sqs");

const sqs = new SQSClient();

exports.handler = async (event) => {
  await sqs.send(new SendMessageCommand({
    QueueUrl: process.env.QUEUE_URL,
    MessageBody: "hello world"
  }));
  return { statusCode: 200, body: "Message sent" };
};
