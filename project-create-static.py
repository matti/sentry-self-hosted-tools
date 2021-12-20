
from optparse import OptionParser
parser = OptionParser()
parser.add_option("--name", dest="name")
parser.add_option("--id", dest="id")
from sentry.models import *

(opts, args) = parser.parse_args()

from sentry.models import *
import hashlib

def createProject(name, id):
  public_key = hashlib.md5(name.encode('utf-8')).hexdigest()
  org = Organization.objects.filter(name="Sentry")[0]
  team = Team.objects.filter(name='Sentry')[0]
  project = Project.objects.create(id=id, organization=org, name=name)
  ProjectTeam.objects.create(project=project, team=team)
  ProjectKey.objects.filter(project=project).update(public_key=public_key)

createProject(opts.name, int(opts.id))
