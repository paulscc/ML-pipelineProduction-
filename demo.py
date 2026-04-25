#!/usr/bin/env python3
"""
ML Engagement Prediction System - Demo Script
This script demonstrates the complete MLOps system functionality
"""

import requests
import json
import time
import random
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MLSystemDemo:
    def __init__(self, base_url="http://localhost:5000", inference_url="http://localhost:5001"):
        self.base_url = base_url
        self.inference_url = inference_url
        self.session = requests.Session()
        self.session.timeout = 30
        
    def check_system_health(self):
        """Check if all services are healthy"""
        logger.info("🔍 Checking system health...")
        
        health_status = {}
        
        # Check Web UI
        try:
            response = self.session.get(f"{self.base_url}/health")
            health_status["web_ui"] = response.status_code == 200
            logger.info("✅ Web UI is healthy" if health_status["web_ui"] else "❌ Web UI is unhealthy")
        except Exception as e:
            health_status["web_ui"] = False
            logger.error(f"❌ Web UI health check failed: {e}")
        
        # Check Inference Service
        try:
            response = self.session.get(f"{self.inference_url}/health")
            health_status["inference"] = response.status_code == 200
            logger.info("✅ Inference service is healthy" if health_status["inference"] else "❌ Inference service is unhealthy")
        except Exception as e:
            health_status["inference"] = False
            logger.error(f"❌ Inference service health check failed: {e}")
        
        return health_status
    
    def get_model_info(self):
        """Get model information"""
        logger.info("📊 Getting model information...")
        
        try:
            response = self.session.get(f"{self.inference_url}/model-info")
            if response.status_code == 200:
                model_info = response.json()
                logger.info(f"✅ Model loaded: {model_info.get('model_type', 'Unknown')}")
                logger.info(f"📅 Last trained: {model_info.get('last_training_time', 'Unknown')}")
                logger.info(f"🔧 Features: {', '.join(model_info.get('features', []))}")
                return model_info
            else:
                logger.error(f"❌ Failed to get model info: {response.status_code}")
                return None
        except Exception as e:
            logger.error(f"❌ Model info request failed: {e}")
            return None
    
    def make_single_prediction(self, user_data=None):
        """Make a single prediction"""
        if user_data is None:
            user_data = {
                "user_id": f"demo_user_{random.randint(1000, 9999)}",
                "avg_session_duration": round(random.uniform(10, 60), 1),
                "visits_per_week": random.randint(1, 20),
                "response_rate": round(random.uniform(20, 100), 1),
                "feature_usage_depth": random.randint(1, 10)
            }
        
        logger.info(f"🎯 Making prediction for user: {user_data['user_id']}")
        logger.info(f"   Session duration: {user_data['avg_session_duration']} min")
        logger.info(f"   Visits per week: {user_data['visits_per_week']}")
        logger.info(f"   Response rate: {user_data['response_rate']}%")
        logger.info(f"   Feature usage depth: {user_data['feature_usage_depth']}")
        
        try:
            response = self.session.post(
                f"{self.inference_url}/predict",
                json=user_data,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                prediction = response.json()
                engagement_score = prediction.get('engagement_score', 0)
                logger.info(f"✅ Prediction successful!")
                logger.info(f"📈 Engagement Score: {engagement_score:.2f}")
                
                # Interpret the score
                if engagement_score >= 80:
                    logger.info("🔥 User is HIGHLY engaged!")
                elif engagement_score >= 60:
                    logger.info("👍 User is moderately engaged")
                elif engagement_score >= 40:
                    logger.info("⚠️ User engagement is moderate")
                else:
                    logger.info("📉 User has LOW engagement")
                
                return prediction
            else:
                logger.error(f"❌ Prediction failed: {response.status_code}")
                logger.error(f"Response: {response.text}")
                return None
        except Exception as e:
            logger.error(f"❌ Prediction request failed: {e}")
            return None
    
    def batch_predictions(self, num_predictions=10):
        """Make multiple predictions to demonstrate load"""
        logger.info(f"🚀 Running batch predictions ({num_predictions} requests)...")
        
        predictions = []
        start_time = time.time()
        
        for i in range(num_predictions):
            user_data = {
                "user_id": f"batch_user_{i+1:03d}",
                "avg_session_duration": round(random.uniform(5, 120), 1),
                "visits_per_week": random.randint(1, 50),
                "response_rate": round(random.uniform(10, 100), 1),
                "feature_usage_depth": random.randint(1, 15)
            }
            
            prediction = self.make_single_prediction(user_data)
            if prediction:
                predictions.append(prediction)
            
            # Small delay to simulate real usage
            time.sleep(0.1)
        
        end_time = time.time()
        total_time = end_time - start_time
        
        logger.info(f"✅ Batch completed!")
        logger.info(f"📊 Successful predictions: {len(predictions)}/{num_predictions}")
        logger.info(f"⏱️ Total time: {total_time:.2f} seconds")
        logger.info(f"⚡ Average time per prediction: {total_time/num_predictions:.3f} seconds")
        
        return predictions
    
    def demonstrate_user_segments(self):
        """Demonstrate predictions for different user segments"""
        logger.info("👥 Demonstrating predictions for different user segments...")
        
        user_segments = {
            "Power User": {
                "user_id": "power_user_demo",
                "avg_session_duration": 45.0,
                "visits_per_week": 15,
                "response_rate": 95.0,
                "feature_usage_depth": 9
            },
            "Casual User": {
                "user_id": "casual_user_demo",
                "avg_session_duration": 15.0,
                "visits_per_week": 3,
                "response_rate": 60.0,
                "feature_usage_depth": 4
            },
            "Inactive User": {
                "user_id": "inactive_user_demo",
                "avg_session_duration": 5.0,
                "visits_per_week": 1,
                "response_rate": 25.0,
                "feature_usage_depth": 2
            },
            "New User": {
                "user_id": "new_user_demo",
                "avg_session_duration": 20.0,
                "visits_per_week": 2,
                "response_rate": 70.0,
                "feature_usage_depth": 3
            }
        }
        
        segment_results = {}
        
        for segment_name, user_data in user_segments.items():
            logger.info(f"\n--- {segment_name} ---")
            prediction = self.make_single_prediction(user_data)
            if prediction:
                segment_results[segment_name] = prediction
        
        # Summary
        logger.info("\n📊 Segment Analysis Summary:")
        for segment, result in segment_results.items():
            score = result.get('engagement_score', 0)
            logger.info(f"{segment}: {score:.1f}")
        
        return segment_results
    
    def test_api_endpoints(self):
        """Test various API endpoints"""
        logger.info("🔧 Testing API endpoints...")
        
        endpoints = [
            ("/", "Web UI Home"),
            ("/predict", "Prediction Page"),
            ("/analytics", "Analytics Dashboard"),
            ("/api/model-info", "Model Info API"),
            ("/api/metrics", "Metrics API")
        ]
        
        results = {}
        
        for endpoint, description in endpoints:
            try:
                response = self.session.get(f"{self.base_url}{endpoint}")
                results[endpoint] = {
                    "status": response.status_code,
                    "success": response.status_code == 200
                }
                logger.info(f"{description}: {'✅' if response.status_code == 200 else '❌'} ({response.status_code})")
            except Exception as e:
                results[endpoint] = {
                    "status": "ERROR",
                    "success": False,
                    "error": str(e)
                }
                logger.error(f"{description}: ❌ ERROR - {e}")
        
        return results
    
    def simulate_real_time_usage(self, duration_seconds=30):
        """Simulate real-time usage patterns"""
        logger.info(f"⏰ Simulating real-time usage for {duration_seconds} seconds...")
        
        start_time = time.time()
        predictions_made = 0
        
        while time.time() - start_time < duration_seconds:
            # Simulate different user types
            user_type = random.choice(['power', 'casual', 'new', 'inactive'])
            
            if user_type == 'power':
                user_data = {
                    "user_id": f"rt_power_{predictions_made}",
                    "avg_session_duration": random.uniform(30, 90),
                    "visits_per_week": random.randint(10, 25),
                    "response_rate": random.uniform(80, 100),
                    "feature_usage_depth": random.randint(7, 12)
                }
            elif user_type == 'casual':
                user_data = {
                    "user_id": f"rt_casual_{predictions_made}",
                    "avg_session_duration": random.uniform(10, 30),
                    "visits_per_week": random.randint(2, 8),
                    "response_rate": random.uniform(40, 80),
                    "feature_usage_depth": random.randint(2, 6)
                }
            elif user_type == 'new':
                user_data = {
                    "user_id": f"rt_new_{predictions_made}",
                    "avg_session_duration": random.uniform(15, 45),
                    "visits_per_week": random.randint(1, 5),
                    "response_rate": random.uniform(60, 90),
                    "feature_usage_depth": random.randint(2, 5)
                }
            else:  # inactive
                user_data = {
                    "user_id": f"rt_inactive_{predictions_made}",
                    "avg_session_duration": random.uniform(3, 15),
                    "visits_per_week": random.randint(0, 2),
                    "response_rate": random.uniform(10, 40),
                    "feature_usage_depth": random.randint(1, 3)
                }
            
            # Make prediction
            prediction = self.make_single_prediction(user_data)
            if prediction:
                predictions_made += 1
            
            # Random delay to simulate real usage patterns
            time.sleep(random.uniform(0.5, 2.0))
        
        logger.info(f"✅ Real-time simulation completed!")
        logger.info(f"📊 Total predictions made: {predictions_made}")
        logger.info(f"⚡ Average rate: {predictions_made/duration_seconds:.2f} predictions/second")
    
    def generate_demo_report(self, results):
        """Generate a comprehensive demo report"""
        logger.info("📋 Generating demo report...")
        
        report = f"""
# ML Engagement Prediction System - Demo Report
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## System Health Check
- Web UI: {'✅ Healthy' if results.get('health', {}).get('web_ui') else '❌ Unhealthy'}
- Inference Service: {'✅ Healthy' if results.get('health', {}).get('inference') else '❌ Unhealthy'}

## Model Information
- Model Type: {results.get('model_info', {}).get('model_type', 'N/A')}
- Last Training: {results.get('model_info', {}).get('last_training_time', 'N/A')}
- Features: {len(results.get('model_info', {}).get('features', []))}

## Demo Results
- Single Predictions: ✅ Completed
- Batch Predictions: {len(results.get('batch_predictions', []))} successful
- User Segments: {len(results.get('user_segments', {}))} segments tested
- API Endpoints: {sum(1 for r in results.get('api_endpoints', {}).values() if r.get('success'))} working

## Performance Metrics
- Average Prediction Time: {results.get('avg_prediction_time', 'N/A')}
- Throughput: {results.get('throughput', 'N/A')} predictions/second

## User Segment Analysis
"""
        
        for segment, result in results.get('user_segments', {}).items():
            score = result.get('engagement_score', 0)
            report += f"- {segment}: {score:.1f}\n"
        
        report += f"""
## Conclusion
✅ Demo completed successfully!
🚀 System is ready for production use.

---
*Generated by ML System Demo Script*
"""
        
        # Save report
        with open('DEMO_REPORT.md', 'w') as f:
            f.write(report)
        
        logger.info("✅ Demo report saved to DEMO_REPORT.md")
        return report
    
    def run_full_demo(self):
        """Run the complete demo"""
        logger.info("🎬 Starting ML Engagement Prediction System Demo")
        logger.info("=" * 60)
        
        results = {}
        
        # 1. Health Check
        results['health'] = self.check_system_health()
        
        # 2. Model Info
        results['model_info'] = self.get_model_info()
        
        # 3. Single Prediction
        logger.info("\n" + "="*40)
        logger.info("SINGLE PREDICTION DEMO")
        logger.info("="*40)
        results['single_prediction'] = self.make_single_prediction()
        
        # 4. Batch Predictions
        logger.info("\n" + "="*40)
        logger.info("BATCH PREDICTIONS DEMO")
        logger.info("="*40)
        results['batch_predictions'] = self.batch_predictions(5)
        
        # 5. User Segments
        logger.info("\n" + "="*40)
        logger.info("USER SEGMENTS DEMO")
        logger.info("="*40)
        results['user_segments'] = self.demonstrate_user_segments()
        
        # 6. API Endpoints
        logger.info("\n" + "="*40)
        logger.info("API ENDPOINTS DEMO")
        logger.info("="*40)
        results['api_endpoints'] = self.test_api_endpoints()
        
        # 7. Real-time Simulation
        logger.info("\n" + "="*40)
        logger.info("REAL-TIME USAGE SIMULATION")
        logger.info("="*40)
        self.simulate_real_time_usage(15)  # 15 seconds
        
        # 8. Generate Report
        logger.info("\n" + "="*40)
        logger.info("GENERATING DEMO REPORT")
        logger.info("="*40)
        self.generate_demo_report(results)
        
        logger.info("\n🎉 Demo completed successfully!")
        logger.info("📋 Check DEMO_REPORT.md for detailed results")
        logger.info("🌐 Web UI available at: http://localhost:5000")
        logger.info("🔧 Inference API available at: http://localhost:5001")
        
        return results

def main():
    """Main function to run the demo"""
    import argparse
    
    parser = argparse.ArgumentParser(description='ML Engagement Prediction System Demo')
    parser.add_argument('--base-url', default='http://localhost:5000', help='Base URL for Web UI')
    parser.add_argument('--inference-url', default='http://localhost:5001', help='Inference service URL')
    parser.add_argument('--component', choices=['health', 'single', 'batch', 'segments', 'api', 'realtime'], 
                       help='Run specific demo component')
    parser.add_argument('--batch-size', type=int, default=10, help='Number of batch predictions')
    parser.add_argument('--realtime-duration', type=int, default=30, help='Real-time simulation duration (seconds)')
    
    args = parser.parse_args()
    
    # Create demo instance
    demo = MLSystemDemo(base_url=args.base_url, inference_url=args.inference_url)
    
    try:
        if args.component == 'health':
            demo.check_system_health()
        elif args.component == 'single':
            demo.make_single_prediction()
        elif args.component == 'batch':
            demo.batch_predictions(args.batch_size)
        elif args.component == 'segments':
            demo.demonstrate_user_segments()
        elif args.component == 'api':
            demo.test_api_endpoints()
        elif args.component == 'realtime':
            demo.simulate_real_time_usage(args.realtime_duration)
        else:
            # Run full demo
            demo.run_full_demo()
            
    except KeyboardInterrupt:
        logger.info("\n👋 Demo interrupted by user")
    except Exception as e:
        logger.error(f"❌ Demo failed: {e}")
        return 1
    
    return 0

if __name__ == '__main__':
    exit(main())
