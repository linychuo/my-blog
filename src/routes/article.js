import { Component } from 'preact';
import yaml from 'yaml';
import Markdown from '../lib/markdown';
import config from '../config';
import loading from './loading.gif';

import hljs from 'highlight.js/lib/highlight';
import javascript from 'highlight.js/lib/languages/javascript';
import python from 'highlight.js/lib/languages/python';
import bash from 'highlight.js/lib/languages/bash';
import clojure from 'highlight.js/lib/languages/clojure';
import html from 'highlight.js/lib/languages/haml';
import 'highlight.js/styles/atom-one-dark.css';

const FRONT_MATTER_REG = /^\s*---\n\s*([\s\S]*?)\s*\n---\n/i;
const LANGUAGES = { javascript, python, bash, clojure, html };
Object.keys(LANGUAGES).forEach(key => hljs.registerLanguage(key, LANGUAGES[key]));

function parseContent(text) {
	let [, frontMatter] = text.match(FRONT_MATTER_REG) || [],
		meta = frontMatter && yaml.eval('---\n' + frontMatter.replace(/^/gm, '  ') + '\n') || {},
		content = text.replace(FRONT_MATTER_REG, '');
	return { meta, content };
}

export default class Article extends Component {
	componentDidMount() {
		let name = this.props.match.params.name;
		let article = config.articles.filter(item => item.name === name);
		article = article && article[0];
		let urlPreix = process.env.NODE_ENV === 'production' ? config.post_url : 'http://localhost:8000/';
		fetch(`${urlPreix}${article.url}`)
			.then(r => r.text())
			.then(r => {
				this.setState(parseContent(r));
			});
	}

	componentDidUpdate() {
		document.querySelectorAll('pre code').forEach(item => {
			let lang = item.getAttribute('class').match(/lang-([a-z]+)/)[1],
				highlighted = hljs.highlightAuto(item.textContent);
			item.setAttribute('class', `hljs lang-${lang}`);
			item.innerHTML = highlighted.value;
		});
	}

	render({ }, { meta, content }) {
		let _content = content ? <Markdown markdown={content} /> : <img src={loading} />;
		return (
			<div class="page-content">
				<div class="wrapper">
					<div class="post">
						<header class="post-header">
							<h1 class="post-title">{meta && meta.title}</h1>
							<p class="post-meta">{meta && meta.date.toUTCString()}</p>
						</header>

						<article class="post-content">{_content}</article>
					</div>
				</div>
			</div>
		);
	}
}
