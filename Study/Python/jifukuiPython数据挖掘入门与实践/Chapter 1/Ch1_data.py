import numpy as np
data_filename="affinity_dataset.txt"
X=np.loadtxt(data_filename) #加载TXT文件
print (X[:5])#打印0~5的内容
num_apple_purchases=0
for sample in X:
	if sample[3]==1:
		num_apple_purchases+=1
print("{0} people bought Apples".format(num_apple_purchases))
from collections import defaultdict
valid_rules=defaultdict(int)
invalid_rules=defaultdict(int)
num_occurances=defaultdict(int)
for sample in X:
	for premise in range(4):
		if sample[premise]==0:
			continue
		num_occurances[premise]+=1
		for conclusion in range (n_features):
			if(premise==conclusion):
				continue
			if sample[conclusion]==1:
				valid_rules[(premise,conclusion)]+=1
			else
				invalid_rules[(premise,conclusion)]+=1
		support =valid_rules
		