import fetch, { FormData } from "node-fetch";
import fs from "fs";
import path from "path";
import process from "process";

const createComment = (screenshotFailures) => {
	const formatScreenshotFailure = ({ directory, diffUrl, newUrl, oldUrl }) => {
		const img = (url) => {
			if (url) {
				return `![](${url})`;
			} else {
				return "None produced.";
			}
		};

		return `| ${directory} | ${img(oldUrl)} | ${img(newUrl)} | ${img(diffUrl)} |`;
	};

	return `
		Screenshot tests failed!

		## Diffs
		| Name | Expected image | Produced image | Diff |
		| ---- | -------------- | -------------- | ---- |
		${screenshotFailures.map(formatScreenshotFailure)}

		## Help
		<details>
			<summary>What is this?</summary>

			Screenshot tests make sure that specific icons look the same as they did before.
			This is important for elements that often mistakenly change, such as alien species.

			If the produced image looks broken, then it is possible your code caused a bug.
			Make sure to test in game to see if you can fix it.
		</details>

		<details>
			<summary>I am changing sprites, it's supposed to look different.</summary>

			If the newly produced sprites are correct, then the tests should be updated.
			Right-click the "produced image", and save it in \`code/modules/unit_tests/screenshots/NAME.png\`.

			If you need help, you can ask maintainers either on Discord or on this pull request.
		</details>

		<details>
			<summary>This is a false positive.</summary>

			If you are sure your code did not cause this failure, especially if it's inconsistent,
			then you may have found a false positive.

			Ask maintainers to rerun the test.

			If you need help, you can ask maintainers either on Discord or on this pull request.
		</details>
	`;
};

export async function showScreenshotTestResults({ github, context, exec }) {
	const { ARTIFACTS_FILE_HOUSE_KEY } = process.env;

	// Step 1. Check if bad-screenshots is in the artifacts
	const { data: { artifacts } } = await github.rest.actions.listWorkflowRunArtifacts({
		owner: context.repo.owner,
		repo: context.repo.repo,
		run_id: context.payload.workflow_run.id,
	});

	console.log(artifacts);

	const badScreenshots = artifacts.find(({ name }) => name === 'bad-screenshots');
	if (!badScreenshots) {
		console.log("No bad screenshots found");
		return;
	}

	// Step 2. Download the screenshots from the artifacts
	const download = await github.actions.downloadArtifact({
		owner: context.repo.owner,
		repo: context.repo.repo,
		artifact_id: badScreenshots.id,
		archive_format: "zip",
	});

	fs.writeFileSync("bad-screenshots.zip", Buffer.from(download.data));

	await exec.exec("unzip bad-screenshots.zip -d bad-screenshots");

	// Step 3. Upload the screenshots
	// 1. Loop over the bad-screenshots directory
	// 2. Upload the screenshot
	// 3. Save the URL
	const uploadFile = async (filename) => {
		if (!fs.existsSync(filename)) {
			return;
		}

		const formData = new FormData();

		formData.set("key", ARTIFACTS_FILE_HOUSE_KEY);

		formData.set("file", fs.createReadStream(filename), {
			filename: path.basename(filename),
			contentType: "image/png",
		});

		return fetch("https://file.house/api/upload", {
			method: "POST",
			body: formData,
		}).then(response => response.json()).then(({ url }) => url);
	};

	const screenshotFailures = [];

	for (const directory of fs.readdirSync("bad-screenshots")) {
		console.log(`Uploading screenshots for ${directory}`);

		let { diffUrl, newUrl, oldUrl };

		await Promise.all([
			uploadFile(path.join("bad-screenshots", directory, "new.png")).then(url => newUrl = url),
			uploadFile(path.join("bad-screenshots", directory, "old.png")).then(url => oldUrl = url),
			uploadFile(path.join("bad-screenshots", directory, "diff.png")).then(url => diffUrl = url),
		]);

		console.log(`New URL (${directory}): ${newUrl}`);
		console.log(`Old URL (${directory}): ${oldUrl}`);
		console.log(`Diff URL (${directory}): ${diffUrl}`);

		screenshotFailures.push({ directory, diffUrl, newUrl, oldUrl });
	}

	if (screenshotFailures.length === 0) {
		console.log("No screenshot failures found");
		return;
	}

	// Step 4. Find the PR
	const result = await github.graphql(`query($workflowRun:String!) {
		node(id: $workflowRun) {
			... on WorkflowRun {
				checkSuite {
					matchingPullRequests(first: 1) {
						nodes {
							number
						}
					}
				}
			}
		}
	}`, {
		workflowRun: context.payload.workflow_run.node_id,
	});

	const prNumber = result.node.checkSuite.matchingPullRequests.nodes[0].number;

	// Step 5. Post the comment
	const comment = createComment(screenshotFailures);

	await github.rest.issues.createComment({
		owner: context.repo.owner,
		repo: context.repo.repo,
		issue_number: prNumber,
		body: comment,
	});
}
