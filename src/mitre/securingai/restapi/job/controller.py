"""The module defining the job endpoints."""

import uuid
from typing import List, Optional

import structlog
from flask_accepts import accepts, responds
from flask_restx import Namespace, Resource
from injector import inject
from structlog.stdlib import BoundLogger

from mitre.securingai.restapi.utils import as_api_parser

from .errors import JobDoesNotExistError, JobSubmissionError
from .model import Job, JobForm, JobFormData
from .schema import JobSchema, job_submit_form_schema
from .service import JobService

LOGGER: BoundLogger = structlog.stdlib.get_logger()

api: Namespace = Namespace(
    "Job",
    description="Job submission and management operations",
)


@api.route("/")
class JobResource(Resource):
    """Shows a list of all jobs, and lets you POST to create new jobs."""

    @inject
    def __init__(
        self,
        *args,
        job_service: JobService,
        **kwargs,
    ) -> None:
        self._job_service = job_service
        super().__init__(*args, **kwargs)

    @responds(schema=JobSchema(many=True), api=api)
    def get(self) -> List[Job]:
        """Gets a list of all submitted jobs."""
        log: BoundLogger = LOGGER.new(
            request_id=str(uuid.uuid4()), resource="job", request_type="GET"
        )  # noqa: F841
        log.info("Request received")
        return self._job_service.get_all(log=log)

    @api.expect(as_api_parser(api, job_submit_form_schema))
    @accepts(job_submit_form_schema, api=api)
    @responds(schema=JobSchema, api=api)
    def post(self) -> Job:
        """Creates a new job via a job submission form with an attached file."""
        log: BoundLogger = LOGGER.new(
            request_id=str(uuid.uuid4()), resource="job", request_type="POST"
        )  # noqa: F841
        job_form: JobForm = JobForm()

        log.info("Request received")

        if not job_form.validate_on_submit():
            log.error("Form validation failed")
            raise JobSubmissionError

        log.info("Form validation successful")
        job_form_data: JobFormData = self._job_service.extract_data_from_form(
            job_form=job_form,
            log=log,
        )
        return self._job_service.submit(job_form_data=job_form_data, log=log)


@api.route("/<string:jobId>")
@api.param("jobId", "A string specifying a job's UUID.")
class JobIdResource(Resource):
    """Shows a single job."""

    @inject
    def __init__(self, *args, job_service: JobService, **kwargs) -> None:
        self._job_service = job_service
        super().__init__(*args, **kwargs)

    @responds(schema=JobSchema, api=api)
    def get(self, jobId: str) -> Job:
        """Gets a job by its unique identifier."""
        log: BoundLogger = LOGGER.new(
            request_id=str(uuid.uuid4()), resource="jobId", request_type="GET"
        )  # noqa: F841
        log.info("Request received", job_id=jobId)
        job: Optional[Job] = self._job_service.get_by_id(jobId, log=log)

        if job is None:
            log.error("Job not found", job_id=jobId)
            raise JobDoesNotExistError

        return job
