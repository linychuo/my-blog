import { Component } from 'preact';
import { MemoryRouter } from 'react-router';
import { Route, Link } from 'react-router-dom';
import Header from './header';
import Footer from './footer';
import Article from '../routes/article';
import config from '../config';
import Markdown from '../lib/markdown';
import loading from '../routes/loading.gif';

const Home = () => (
	<div class="page-content">
		<div class="wrapper">
			<div>
				<ul class="post-list">
					{config.articles.filter(article => article.showOnMain).map(article => (
						<li>
							<span class="post-meta">{article.created}</span>
							<h2><Link class="post-link" to={`/article/${article.name}`}>{article.name}</Link></h2>
						</li>
					))}
				</ul>
			</div>
		</div>
	</div>
);

class About extends Component {
	componentDidMount() {
		let urlPreix = process.env.NODE_ENV === 'production' ? config.post_url : 'http://localhost:8000/';
		fetch(`${urlPreix}about.markdown`).then(r => this.setState(r.text()))
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

const App = () => (
	<MemoryRouter>
		<div>
			<Header />
			<Route exact path="/" component={Home} />
			<Route path="/about" component={About} />
			<Route path="/article/:name" component={Article} />
			<Footer />
		</div>
	</MemoryRouter>
);

export default App;
