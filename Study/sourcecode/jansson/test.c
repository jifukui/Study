#include <stdio.h>
#include <jansson.h>
//int data(json_t *)
int main()
{
	json_t *obj;
	char *str;
	json_t *ob;
	json_t *ob1;
	json_t *ob2;
	json_t *ob3;
	ob=json_object();
	obj=json_object();
	ob1=json_object();
	ob2=json_array();
	ob3=json_object();
	json_object_set_new(ob3,"sex",json_string("man"));
	json_object_set_new(ob3,"age",json_integer(17));
	json_array_append(ob2,json_string("football"));
	json_array_append(ob2,json_string("bastketball"));
	json_array_append(ob2,json_integer(236));
	json_object_set_new(ob1,"name",json_string("jifukui"));
	json_object_set_new(obj,"dangdang",ob3);
	//json_object_set_new(ob1,"like",json_array());
	json_object_set_new(ob,"test",obj);
	json_object_set_new(ob,"test1",ob1);
	json_object_set_new(ob1,"like",ob2);
	json_object_set_new(obj,"name",json_string("jifukui"));
	json_object_set_new(obj,"like",json_string("football"));
	json_object_set_new(obj,"weight",json_integer(120));
	json_object_set_new(ob,"haha",json_string("I am jifukui"));
	str=json_dumps(obj,JSON_PRESERVE_ORDER);
	printf("str is %s\n",str);
	str=json_dumps(ob,JSON_PRESERVE_ORDER);
	printf("str is %s\n",str);
	json_error_t error;
	json_t *ji;
	ji=json_loads(str,0,&error);
	if(!ji)
	{
		printf("decode error\n");
	}
	else
	{
		printf("decode successful\n");
		printf("The type of ji is %d\n",json_typeof(ji));
		int n=json_object_size(ji);
		printf("The number is %d\n",n);
		void * iter;
		iter=json_object_iter(ji);
		while(iter)
		{
			const char *key;
        		json_t *value1;
        		key = json_object_iter_key(iter);
        		value1 = json_object_iter_value(iter);
        		printf("The key is %s\n",key);
			json_t *iter1;
			iter1=json_object_iter(value1);
			while(iter1)
			{
				printf("The second\n");
				const char *key1;
				json_t *value2;
	                        key1 = json_object_iter_key(iter);
        	                value2 = json_object_iter_value(iter);
                	        printf("The key is %s\n",key1);
				iter1=json_object_iter_next(iter,iter1);
			}
        		iter = json_object_iter_next(ji, iter);
		}
		free(ji);
	}
	free(str);
	json_decref(obj);
	json_decref(ob);
	json_decref(ob1);
	json_decref(ob2);
	return 0;
}

