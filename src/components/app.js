import { h, Component } from 'preact';
import Header from './header';
import Footer from './footer';
import { Router } from 'preact-router';

import About from '../routes/about';
import Home from '../routes/home';
import Article from '../routes/article';

export default class App extends Component {
	handleRoute = e => {
		this.currentUrl = e.url;
	};

	render() {
		return (
			<div>
				<Header/>
				<Router onChange={this.handleRoute}>
					<Home path="/"/>
					<About path="/about"/>
					<Article path="/article/:name"/>
				</Router>
				<Footer/>
			</div>
		);
	}
}