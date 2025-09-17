# Java CDK Assessment with LocalStack

This assessment now supports **LocalStack** for local AWS service simulation, making it more accessible and cost-effective for candidates.

## 🚀 Quick Start with LocalStack

### Prerequisites
- Docker and Docker Compose
- Java 11+
- Maven 3.6+
- Node.js 14+

### Setup Steps

1. **Start LocalStack**:
   ```bash
   ./start-localstack.sh
   ```

2. **Set up the assessment**:
   ```bash
   ./setup-java-cdk.sh
   ```

3. **Run an exercise**:
   ```bash
   cd exercises/1-lambda-function
   mvn test
   ```

4. **Stop LocalStack when done**:
   ```bash
   ./stop-localstack.sh
   ```

## 🔧 LocalStack Configuration

### Services Available
- **Lambda**: Function execution and management
- **S3**: Object storage and event notifications
- **API Gateway**: REST API creation and management
- **DynamoDB**: NoSQL database with GSI support
- **IAM**: Identity and access management
- **CloudFormation**: Infrastructure as code
- **CloudWatch Logs**: Logging and monitoring

### Environment Variables
LocalStack automatically sets these environment variables:
```bash
AWS_ENDPOINT_URL=http://localhost:4566
AWS_DEFAULT_REGION=us-east-1
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
```

## 🧪 Testing with LocalStack

### Test Structure
- **LocalStackTestBase**: Base class for LocalStack tests
- **LocalStackConfig**: Utility class for configuration
- **Template Assertions**: CDK assertions work with LocalStack

### Example Test
```java
public class LambdaFunctionTest extends LocalStackTestBase {
    
    @Test
    public void testLambdaFunctionExists() {
        template.hasResourceProperties("AWS::Lambda::Function", 
            Match.objectLike(Map.of(
                "Runtime", "java11",
                "Handler", "com.myorg.Handler::handleRequest"
            ))
        );
    }
}
```

## 🐛 Debugging LocalStack

### Check LocalStack Status
```bash
curl http://localhost:4566/_localstack/health
```

### View LocalStack Logs
```bash
docker-compose logs -f localstack
```

### Reset LocalStack Data
```bash
./stop-localstack.sh --clean
./start-localstack.sh
```

## 🔄 LocalStack vs AWS

| Feature | LocalStack | AWS |
|---------|------------|-----|
| **Cost** | Free | Pay per use |
| **Speed** | Fast | Network dependent |
| **Credentials** | Not required | Required |
| **Persistence** | Optional | Always |
| **Real Services** | Simulated | Real |

## 📁 File Structure

```
java-cdk/
├── docker-compose.yml          # LocalStack configuration
├── localstack-config.json      # LocalStack settings
├── start-localstack.sh         # Start LocalStack
├── stop-localstack.sh          # Stop LocalStack
├── exercises/
│   └── 1-lambda-function/
│       ├── cdk.json            # CDK config with LocalStack
│       └── src/
│           ├── main/java/
│           │   └── LocalStackConfig.java
│           └── test/java/
│               └── LocalStackTestBase.java
```

## 🎯 Benefits for Assessment

1. **No AWS Account Required**: Candidates can work without AWS credentials
2. **No Costs**: No AWS charges for testing
3. **Fast Iteration**: Quick feedback on code changes
4. **Isolated Environment**: Each candidate gets a clean environment
5. **Real AWS APIs**: Tests use actual AWS service APIs

## 🔧 Troubleshooting

### LocalStack Won't Start
- Check if Docker is running: `docker info`
- Check port 4566 is available: `lsof -i :4566`
- Restart Docker if needed

### Tests Fail to Connect
- Verify LocalStack is running: `curl http://localhost:4566/_localstack/health`
- Check environment variables are set
- Ensure tests extend `LocalStackTestBase`

### Performance Issues
- Increase Docker memory allocation
- Use `--clean` flag to reset data
- Check Docker logs for errors

## 🚀 Advanced Usage

### Custom LocalStack Configuration
Edit `localstack-config.json` to customize services and settings.

### Multiple Test Environments
Use different Docker Compose files for different test scenarios.

### Integration with CI/CD
LocalStack can be integrated into CI/CD pipelines for automated testing.

## 📚 Additional Resources

- [LocalStack Documentation](https://docs.localstack.cloud/)
- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [JUnit 5 Documentation](https://junit.org/junit5/docs/current/user-guide/)
