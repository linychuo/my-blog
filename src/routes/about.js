import { Component } from 'preact';

export default class About extends Component {
	render() {
		return (
			<div class="page-content">
			    <div class="wrapper">
				    <div class="post">
						<header class="post-header">
							<h1 class="post-title">About</h1>
						</header>

						<article class="post-content">
							<p><a href="https://github.com/linychuo">github.com/linychuo</a></p>
							<p><a href="https://bitbucket.org/linychuo">bitbucket.org/linychuo</a></p>
						</article>
					</div>
				</div>
			</div>
		);
	}
}
