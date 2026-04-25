import numpy as np
from sklearn.linear_model import LinearRegression
import datetime

# Simple inference example
X = np.array([[1], [2], [3], [4], [5]])
y = np.array([2, 4, 6, 8, 10])

model = LinearRegression()
model.fit(X, y)

# Make prediction
test_input = np.array([[6]])
prediction = model.predict(test_input)[0]

print('🤖 Simple ML Inference Result')
print(f'Input: {test_input[0][0]}')
print(f'Prediction: {prediction:.2f}')
print(f'Timestamp: {datetime.datetime.now()}')
print(f'Model trained on {len(X)} samples')
