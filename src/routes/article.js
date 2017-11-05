import { Component } from 'preact';
import yaml from 'yaml';
import Markdown from '../lib/markdown';
import config from '../config';

const FRONT_MATTER_REG = /^\s*\-\-\-\n\s*([\s\S]*?)\s*\n\-\-\-\n/i;

function parseContent(text) {
	let [,frontMatter] = text.match(FRONT_MATTER_REG) || [],
		meta = frontMatter && yaml.eval('---\n'+frontMatter.replace(/^/gm,'  ')+'\n') || {},
		content = text.replace(FRONT_MATTER_REG, '');
	return {meta, content};
}

export default class Article extends Component {
	componentWillMount() {
		let name = this.props.name;
		let article = config.articles.find(item => item.name === name );
		fetch(article.url)
			.then(r => r.text())
			.then(r => {
				this.setState(parseContent(r));
			});
	}

	render({ name }, { meta, content }) {
		return (
			<div class="page-content">
      			<div class="wrapper">
        			<div class="post">
						<header class="post-header">
							<h1 class="post-title">{meta && meta.title}</h1>
							<p class="post-meta">{meta && meta.data && meta.date.toDateString()}</p>
						</header>

						<article class="post-content">
							{content && <Markdown markdown={content}/>}
						</article>
					</div>
  				</div>
  			</div>
		);
	}
}