import config from '../config';
import { Component } from 'preact';
import Markdown from '../lib/markdown';
import loading from './loading.gif';


export default class About extends Component {
	componentDidMount() {
		let urlPreix = process.env.NODE_ENV === 'production' ? config.post_url : 'http://localhost:8000/';
		fetch(`${urlPreix}about.markdown`).then(r => {
			return r.text();
		}).then(txt => {
			this.setState({ content: txt });
		});
	}

	render({ }, { content }) {
		let _content = content ? <Markdown markdown={content} /> : <img src={loading} />;
		return (
			<div class="page-content">
				<div class="wrapper">
					<div class="post">
						<article class="post-content">{_content}</article>
					</div>
				</div>
			</div>
		);
	}
};
