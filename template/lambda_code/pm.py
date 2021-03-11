"""
PM 작업 동안 안내문 페이지로 포워딩하기 위해 ELB 에서 타겟을 변경/복원 한다.

GET     /promo/pm        # PM 연결 상태 조회
POST    /promo/pm        # PM 활성화
DELETE  /promo/pm        # PM 비활성화

"""

import boto3
from pprint import *
import sys
import os
import json
import logging



###################################################################################################
###########################################################################################
if __name__ == '__main__':

  # os.environ['AWS_PROFILE'] = '11st_dev'
  os.environ['listener_arns'] = 'arn:aws:elasticloadbalancing:ap-northeast-2:446804614856:listener/net/testnlb/8ac6631be8d39475/86341fe8bdb4fac9,arn:aws:elasticloadbalancing:ap-northeast-2:446804614856:listener/net/testnlb/8ac6631be8d39475/85790c4a0a935539'
  os.environ['target_group_arn_pm'] = 'arn:aws:elasticloadbalancing:ap-northeast-2:446804614856:targetgroup/tg-pm/5b013850a480b986'
  os.environ['target_group_arn_service'] = 'arn:aws:elasticloadbalancing:ap-northeast-2:446804614856:targetgroup/testtg/8d327d0b5807c740,arn:aws:elasticloadbalancing:ap-northeast-2:446804614856:targetgroup/testtg443/6006e59c7aed7780'

  pass
###################################################################################################
###########################################################################################



# AWS Xray 연동 시 추가 코드
# from aws_xray_sdk.core import xray_recorder
# from aws_xray_sdk.core import patch_all
# patch_all()


session = boto3.Session()
client = session.client('elbv2')


MSG_IN_SERVICE = 'in Service'
MSG_IN_PM = 'in PM'    # (Prevention-Maintenance)
MSG_UNKNOWN = 'UnKnown'

ERROR_CODE_SUCCESS = 200
ERROR_CODE_FROBIDDEN = 403
ERROR_CODE_INTERNAL_SERVER_ERROR = 500



def switch_target(listener_arns, target_group_arn):
  """
  ELB 리스너의 타겟을 변경 한다.
  :param listener_arns: 변경할 리스너 arn 배열 (리스너는 80, 443 등 여러개 될 수 있다. 개수를 맞추지 않으면 rotation 하면서 타겟에 등록된다.)
  :param target_group_arn: 리스너에 적용할 타겟 그룹 arn 배열
  :return: 200(성공), 500(에러)
  """

  ret = ERROR_CODE_INTERNAL_SERVER_ERROR

  try:
    for i, listener_arn in enumerate(listener_arns):
      response = client.modify_listener(
        ListenerArn=listener_arn,
        DefaultActions=[
          {
            'Type': 'forward',
            'TargetGroupArn': target_group_arn[i % len(target_group_arn)],
            'Order': i + 1,
          }
        ]
      )

    ret = ERROR_CODE_SUCCESS

  except Exception as e:
    logging.exception(e)
    pass

  return ret, None




def status_pm(listener_anrs, target_group_arn_service,target_group_arn_pm):
  """
  ELB 리스너의 타겟이 PM 인지, Service 인지 조회 한다.
  :param listener_anrs: 조회할 리스너 arn 배열 (리스너는 80, 443 등 여러개 될 수 있다. 개수를 맞추지 않으면 rotation 하면서 타겟에 등록된다.)
  :param target_group_arn_service: 서비스 서버에 대한 타겟 그룹 arn
  :param target_group_arn_pm: PM 서버에 대한 타겟 그룹 arn
  :return: [200(성공), 타겟 종류(in Service, in PM, UnKnown)]
  """


  err_msg = MSG_UNKNOWN

  try:
    response = client.describe_listeners(
      ListenerArns=listener_anrs
    )

    target_service_cnt = 0
    target_pm_cnt = 0

    listeners = response.get('Listeners')
    for i, listener in enumerate(listeners):
      tg_arn = listener.get('DefaultActions')[0].get('TargetGroupArn')
      if tg_arn == target_group_arn_pm[i % len(target_group_arn_pm)]:
        target_pm_cnt += 1
      elif tg_arn == target_group_arn_service[i % len(target_group_arn_service)]:
        target_service_cnt += 1

    print("listener cnt=", len(listeners), ", svc cnt=", target_service_cnt, ", pm cnt=", target_pm_cnt, sep="")

    if target_pm_cnt == len(listeners):
      err_msg = MSG_IN_PM
    elif target_service_cnt == len(listeners):
      err_msg = MSG_IN_SERVICE
    else:
      err_msg = MSG_UNKNOWN


  except Exception as e:
    logging.exception(e)

  # return ret
  return ERROR_CODE_SUCCESS, err_msg





def lambda_handler(event, context):

  # 환경 변경 변수로 설정된 리스너(,로 구분된), 타겟 그룹(service, pm) 정보를 가져 온다.
  listener_arns = os.environ.get('listener_arns')
  listener_arns = listener_arns.split(",")
  target_group_arn_pm = os.environ.get('target_group_arn_pm').split(",")
  target_group_arn_service = os.environ.get('target_group_arn_service').split(",")

  # HTTP method 종류에 따른 처리할 액션을 구분 하기 위한 용도
  # method = event.get('requestContext').get('http').get('method')   ## for api-gw http protocal
  method = event.get('httpMethod')  ## for api-gw rest proxy protocal
  # path = event.get('path')  ## for api-gw rest proxy protocal

  print("method : ", method)

  if method == 'GET':
    error_code, error_msg = status_pm(listener_arns, target_group_arn_service, target_group_arn_pm)
  elif method == 'POST':
    error_code, error_msg = switch_target(listener_arns, target_group_arn_pm)
  elif method == 'DELETE':
    error_code, error_msg = switch_target(listener_arns, target_group_arn_service)
  else:
    error_code, error_msg = ERROR_CODE_FROBIDDEN, None

  ret = {
    "isBase64Encoded": False,
    "statusCode": error_code,
    "body": error_msg
  }

  print('response :', method, ret)

  return ret




###################################################################################################
###########################################################################################
if __name__ == '__main__':

  print("~~~~~~~~~~")
  event = json.loads('{ "httpMethod": "GET" }')
  print("Res : ", lambda_handler(event, None))
  event = json.loads('{ "httpMethod": "POST" }')
  print("Res : ", lambda_handler(event, None))
  event = json.loads('{ "httpMethod": "GET" }')
  print("Res : ", lambda_handler(event, None))

  event = json.loads('{ "httpMethod": "DELETE" }')
  print("Res : ", lambda_handler(event, None))
  event = json.loads('{ "httpMethod": "GET" }')
  print("Res : ", lambda_handler(event, None))


  pass
###################################################################################################
###########################################################################################

